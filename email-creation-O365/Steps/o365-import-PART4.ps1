$InputFile = Import-CSV "$PSScriptRoot\Import-Users.csv"
foreach ($User in $InputFile)
{
$Login = $User.Login
$Email = $User.Email

Write-Host -Foreground "Yellow" "Applying US Location for $Email ..."

Update-MgUser -UserId $Email -UsageLocation US

Start-Sleep -Seconds 2

Write-Host -Foreground "Yellow" "Applying O365 E1 License for $Email ..."
$EmsSku = Get-MgSubscribedSku -All | Where SkuPartNumber -eq 'STANDARDPACK'
$disabledPlans = $EmsSku.ServicePlans | where ServicePlanName -in ("PLACES_CORE", "Bing_Chat_Enterprise", "MESH_IMMERSIVE_FOR_TEAMS", "MESH_AVATARS_ADDITIONAL_FOR_TEAMS", "MESH_AVATARS_FOR_TEAMS", "MICROSOFTBOOKINGS", "VIVA_LEARNING_SEEDED", "POWER_VIRTUAL_AGENTS_O365_P1", "CDS_O365_P1", "PROJECT_O365_P1", "DYN365_CDS_O365_P1", "KAIZALA_O365_P2", "WHITEBOARD_PLAN1", "MYANALYTICS_P2", "OFFICEMOBILE_SUBSCRIPTION", "BPOS_S_TODO_1", "FORMS_PLAN_E1", "STREAM_O365_E1", "Deskless", "FLOW_O365_P1", "POWERAPPS_O365_P1", "PROJECTWORKMANAGEMENT", "SWAY", "YAMMER_ENTERPRISE", "MCOSTANDARD") | Select -ExpandProperty ServicePlanId
$addLicenses = @(
  @{SkuId = $EmsSku.SkuId
  DisabledPlans = $disabledPlans
  }
  )

Set-MgUserLicense -UserId $Email -AddLicenses $addLicenses -RemoveLicenses @()
Start-Sleep -Seconds 2
}
Start-Sleep -Seconds 300

