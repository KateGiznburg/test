Install-Module -Name "AzureAD" -Scope CurrentUser
Import-Module -Name "AzureAD"
Connect-AzureAD
Remove-AzureADServicePrincipal -ObjectId 861fb414-8773-49c6-912b-46de5d91d1cf