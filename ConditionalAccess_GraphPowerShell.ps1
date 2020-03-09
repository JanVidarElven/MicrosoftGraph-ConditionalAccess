# ***** ConditionalAccess_GraphPowerShell.ps1 *****
# ***** This script creates Conditional Access Policies from Json Payload Files *****
# ***** Script is intended to run interactively as per current, block-by-block *****
# ***** Created by Jan Vidar Elven, Skill AS *****
# ***** Last Modified: 02.03.2020 *****

# 0. Variables you need to change for use in script

# Use App Registration Client Id as described in README.MD
$graphClientId = "<your-client-id>"
$graphTenantName = "<your-tenant>.onmicrosoft.com"
$orgName = "<Your Org Name>"

# If you have a break glass admin account or on-premises directory synchronization account 
# you want to excempt from policies, add their object id's here
# If blank, they will not be added to policies
$breakGlassObjectId = ""
$syncAccountObjectId = ""

# 1. Connect to Graph
$resource = "https://graph.microsoft.com/"
$authUrl = "https://login.microsoftonline.com/$graphTenantName"

# Using Device Code Flow that support Modern Authentication for Delegated User
$postParams = @{ resource = "$resource"; client_id = "$graphClientId" }
$response = Invoke-RestMethod -Method POST -Uri "$authurl/oauth2/devicecode" -Body $postParams
Write-Host $response.message
# HALT: Go to Browser logged in as User with access to Azure AD Conditional Access and tenant and paste in Device Code

$tokenParams = @{ grant_type = "device_code"; resource = "$resource"; client_id = "$graphClientId"; code = "$($response.device_code)" }
$tokenResponse = $null
# Provided Successful Authentication, the following should return Access and Refresh Tokens: 
$tokenResponse = Invoke-RestMethod -Method POST -Uri "$authurl/oauth2/token" -Body $tokenParams
# Save Access Token and Refresh Token for later use
$accessToken = $tokenResponse.access_token
$refreshToken = $tokenResponse.refresh_token

# 2. Create Custom OrgName baseline policies to replace Microsoft Preview Baseline Policies that were removed 29th Feb 2020

# Get the JSON templates for the CA policies
$jsonRequireMFAforAdmins = Get-Content -Raw -Path .\ConditionalAccess_Require_MFA_for_Admins.json | ConvertFrom-Json
$jsonBlockLegacyAuth = Get-Content -Raw -Path .\ConditionalAccess_Block_legacy_authentication.json | ConvertFrom-Json
$jsonRequireMFAforServiceMgmt = Get-Content -Raw -Path .\ConditionalAccess_Require_MFA_for_Service_Management.json | ConvertFrom-Json
$jsonEndUserProtection = Get-Content -Raw -Path .\ConditionalAccess_End_user_protection.json | ConvertFrom-Json

# Replace the OrgName placeholder with your orgName variable in the Template
$jsonRequireMFAforAdmins.displayName = $jsonRequireMFAforAdmins.displayName.Replace("<OrgName>",$orgName)
$jsonBlockLegacyAuth.displayName = $jsonBlockLegacyAuth.displayName.Replace("<OrgName>",$orgName)
$jsonRequireMFAforServiceMgmt.displayName = $jsonRequireMFAforServiceMgmt.displayName.Replace("<OrgName>",$orgName)
$jsonEndUserProtection.displayName = $jsonEndUserProtection.displayName.Replace("<OrgName>",$orgName)

# Then clear any placeholder values for excluded users in the templates
# Using ArrayList because array converted from JSON is fixed size
[System.Collections.ArrayList]$arrayListExcludeUsersMFAforAdmins = $jsonRequireMFAforAdmins.conditions.users.excludeUsers
[System.Collections.ArrayList]$arrayListExcludeUsersBlockLegacyAuth = $jsonBlockLegacyAuth.conditions.users.excludeUsers
[System.Collections.ArrayList]$arrayListExcludeUsersMFAforServiceMgmt = $jsonRequireMFAforServiceMgmt.conditions.users.excludeUsers
[System.Collections.ArrayList]$arrayListExcludeUsersEndUserProtection = $jsonEndUserProtection.conditions.users.excludeUsers
$arrayListExcludeUsersMFAforAdmins.Clear()
$arrayListExcludeUsersBlockLegacyAuth.Clear()
$arrayListExcludeUsersMFAforServiceMgmt.Clear()
$arrayListExcludeUsersEndUserProtection.Clear()

# If break glass admin object id variable set, add it to policies
If ($breakGlassObjectId) {
    $arrayListExcludeUsersMFAforAdmins.Add($breakGlassObjectId)
    $arrayListExcludeUsersBlockLegacyAuth.Add($breakGlassObjectId)
    $arrayListExcludeUsersMFAforServiceMgmt.Add($breakGlassObjectId)
    $arrayListExcludeUsersEndUserProtection.Add($breakGlassObjectId)
}
# If on-premises directory sync account object id variable set, add it to policies
If ($syncAccountObjectId) {
    $arrayListExcludeUsersMFAforAdmins.Add($syncAccountObjectId)
    $arrayListExcludeUsersMFAforServiceMgmt.Add($syncAccountObjectId)
    $arrayListExcludeUsersEndUserProtection.Add($syncAccountObjectId)
}

# Add back the updated arrays
$jsonRequireMFAforAdmins.conditions.users.excludeUsers = $arrayListExcludeUsersMFAforAdmins
$jsonBlockLegacyAuth.conditions.users.excludeUsers = $arrayListExcludeUsersBlockLegacyAuth
$jsonRequireMFAforServiceMgmt.conditions.users.excludeUsers = $arrayListExcludeUsersMFAforServiceMgmt
$jsonEndUserProtection.conditions.users.excludeUsers = $arrayListExcludeUsersEndUserProtection

# 3. Create the Conditional Access Policies
New-GraphConditionalAccessPolicy -requestBody ($jsonRequireMFAforAdmins | ConvertTo-Json -Depth 3) -accessToken $accessToken
New-GraphConditionalAccessPolicy -requestBody ($jsonBlockLegacyAuth | ConvertTo-Json -Depth 3) -accessToken $accessToken
New-GraphConditionalAccessPolicy -requestBody ($jsonRequireMFAforServiceMgmt | ConvertTo-Json -Depth 3) -accessToken $accessToken
New-GraphConditionalAccessPolicy -requestBody ($jsonEndUserProtection | ConvertTo-Json -Depth 3) -accessToken $accessToken

function New-GraphConditionalAccessPolicy {
    <#
    .SYNOPSIS
    Custom Function for Creating New Conditional Access Policies via Microsoft Graph.
    .DESCRIPTION
    Require a valid Access Token and a JSON request body as parameters.
    .EXAMPLE
    New-GraphConditionalAccessPolicy -requestBody $jsonRequestBody -accessToken $accessToken
    .NOTES
    Created by Jan Vidar Elven, Skill AS.
    Last modified: March 2020.
    #>
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        $requestBody,
        [Parameter(Mandatory = $true)]
        $accessToken 
    )

    $conditionalAccessURI = "https://graph.microsoft.com/beta/conditionalAccess/policies"

    $conditionalAccessPolicyResponse = Invoke-RestMethod -Method Post -Uri $conditionalAccessURI -Headers @{"Authorization"="Bearer $accessToken"} -Body $requestBody -ContentType "application/json"

    $conditionalAccessPolicyResponse     
}
