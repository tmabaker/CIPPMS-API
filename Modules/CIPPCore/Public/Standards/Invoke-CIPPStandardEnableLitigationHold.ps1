function Invoke-CIPPStandardEnableLitigationHold {
    <#
    .FUNCTIONALITY
        Internal
    .COMPONENT
        (APIName) EnableLitigationHold
    .SYNOPSIS
        (Label) Enable Litigation Hold for all users
    .DESCRIPTION
        (Helptext) Enables litigation hold for all UserMailboxes with a valid license.
        (DocsDescription) Enables litigation hold for all UserMailboxes with a valid license.
    .NOTES
        CAT
            Exchange Standards
        TAG
        ADDEDCOMPONENT
            {"type":"textField","name":"standards.EnableLitigationHold.days","required":false,"label":"Days to apply for litigation hold"}
        IMPACT
            Low Impact
        ADDEDDATE
            2024-06-25
        POWERSHELLEQUIVALENT
            Set-Mailbox -LitigationHoldEnabled \$true
        RECOMMENDEDBY
        UPDATECOMMENTBLOCK
            Run the Tools\Update-StandardsComments.ps1 script to update this comment block
    .LINK
        https://docs.cipp.app/user-documentation/tenant/standards/list-standards
    #>

    param($Tenant, $Settings)
    $TestResult = Test-CIPPStandardLicense -StandardName 'EnableLitigationHold' -TenantFilter $Tenant -RequiredCapabilities @('EXCHANGE_S_STANDARD', 'EXCHANGE_S_ENTERPRISE', 'EXCHANGE_LITE') #No Foundation because that does not allow powershell access

    if ($TestResult -eq $false) {
        Write-Host "We're exiting as the correct license is not present for this standard."
        return $true
    } #we're done.
    ##$Rerun -Type Standard -Tenant $Tenant -Settings $Settings 'EnableLitigationHold'

    try {
        $MailboxesNoLitHold = New-ExoRequest -tenantid $Tenant -cmdlet 'Get-Mailbox' -cmdParams @{ Filter = 'LitigationHoldEnabled -eq "False"' } -Select 'UserPrincipalName,PersistedCapabilities,LitigationHoldEnabled' |
        Where-Object { $_.PersistedCapabilities -contains 'BPOS_S_DlpAddOn' -or $_.PersistedCapabilities -contains 'BPOS_S_Enterprise' }
    }
    catch {
        $ErrorMessage = Get-NormalizedError -Message $_.Exception.Message
        Write-LogMessage -API 'Standards' -Tenant $Tenant -Message "Could not get the EnableLitigationHold state for $Tenant. Error: $ErrorMessage" -Sev Error
        return
    }

    if ($Settings.remediate -eq $true) {
        if ($null -eq $MailboxesNoLitHold) {
            Write-LogMessage -API 'Standards' -tenant $Tenant -message 'Litigation Hold already enabled for all accounts' -sev Info
        } else {
            try {
                $Request = $MailboxesNoLitHold | ForEach-Object {
                    $params = @{
                        CmdletInput = @{
                            CmdletName = 'Set-Mailbox'
                            Parameters = @{ Identity = $_.UserPrincipalName; LitigationHoldEnabled = $true }
                        }
                    }
                    if ($null -ne $Settings.days) {
                        $params.CmdletInput.Parameters['LitigationHoldDuration'] = $Settings.days
                    }
                    $params
                }


                $BatchResults = New-ExoBulkRequest -tenantid $Tenant -cmdletArray @($Request)
                $BatchResults | ForEach-Object {
                    if ($_.error) {
                        $ErrorMessage = Get-NormalizedError -Message $_.error
                        Write-Host "Failed to Enable Litigation Hold for $($_.Target). Error: $ErrorMessage"
                        Write-LogMessage -API 'Standards' -tenant $Tenant -message "Failed to Enable Litigation Hold for $($_.Target). Error: $ErrorMessage" -sev Error
                    }
                }
            } catch {
                $ErrorMessage = Get-NormalizedError -Message $_.Exception.Message
                Write-LogMessage -API 'Standards' -tenant $Tenant -message "Failed to Enable Litigation Hold for all accounts. Error: $ErrorMessage" -sev Error
            }
        }

    }

    if ($Settings.alert -eq $true) {
        if (($MailboxesNoLitHold | Measure-Object).Count -gt 0) {
            Write-StandardsAlert -message "Mailboxes without Litigation Hold: $($MailboxesNoLitHold.Count)" -object $MailboxesNoLitHold -tenant $Tenant -standardName 'EnableLitigationHold' -standardId $Settings.standardId
            Write-LogMessage -API 'Standards' -tenant $Tenant -message "Mailboxes without Litigation Hold: $($MailboxesNoLitHold.Count)" -sev Info
        } else {
            Write-LogMessage -API 'Standards' -tenant $Tenant -message 'All mailboxes have Litigation Hold enabled' -sev Info
        }
    }

    if ($Settings.report -eq $true) {
        $filtered = $MailboxesNoLitHold | Select-Object -Property UserPrincipalName
        $state = $filtered ? $MailboxesNoLitHold : $true
        Set-CIPPStandardsCompareField -FieldName 'standards.EnableLitigationHold' -FieldValue $state -Tenant $Tenant
        Add-CIPPBPAField -FieldName 'EnableLitHold' -FieldValue $filtered -StoreAs json -Tenant $Tenant
    }
}
