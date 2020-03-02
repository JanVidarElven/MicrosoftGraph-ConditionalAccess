# MicrosoftGraph-ConditionalAccess
Working with Conditional Access Policies in Azure AD using Microsoft Graph.

## Baseline policies (Preview)

The previous Azure AD Conditional Access Baseline policies were announced by Microsoft to be removed February 29th 2020. Organizations must now either enable Microsoft Security Defaults (https://docs.microsoft.com/en-us/azure/active-directory/fundamentals/concept-fundamentals-security-defaults) or create their own custom Conditional Access policies to achieve the same level of protection as the baseline policies.

## Templates for replacing the baseline policies

In this repository I've created templates that can be used for replacing the baseline policies. These templates are pre-configured with basically the same settings as the Microsoft baselines. Follow the guidelines in this README for deploying them.

The following templates are provided in JSON format:

* Require MFA for Admins
* Require MFA for Service Management
* Block legacy authentication
* End user protection

Important! In the JSON files you will see placeholder values for excluding users from policies. You should always exclude a break the glass admin account (if you have one, and you should), and the on-premises directory synchronization accounts. You might have other user accounts to exclude also. You will need to know their object id's in your tenant:

```json
            "excludeUsers": [
                "<object-id-break-glass-admin>",
                "<object-id-on-premises-sync-account>"
            ],
```

You should also change the Display Name of the policy to reflect your Organization and any naming guidelines you might have, and in my template I have decided to create them initially as disabled:

```json
{
    "displayName": "<OrgName> baseline policy: Require MFA for admins",
    "state": "disabled",

```

Note also that the End User Protection JSON template require MFA when Sign-In Risk is Medium or above, which is the only setting that is programmatically available via Graph today, the other settings that require MFA registration and require password change when High User Risk is not available in Graph yet.

## Deploy the Custom Protection Templates

This repository explains how to deploy the templates this way:

* Using Graph Explorer
* Using PowerShell (coming soon)

### Deploy the custom templates using Graph Explorer

1. Sign in to Graph Explorer (https://aka.ms/ge) using a work account that either is a Global Administrator or Conditional Access Administrator.
2. You will need to Modify Permission so that you have Policy.Read.All and Policy.ReadWrite.ConditionalAccess. Sign out and in again, consenting to the permissions for Graph Explorer. (Don't consent on behalf of the entire organization, you only need this for your current admin user).
3. To verify permissions, try a GET query for https://graph.microsoft.com/beta/conditionalAccess/policies. You should get a response where any existing CA policies are listed.
4. Then, for each of the provided templates, change to a POST query, using the same URI https://graph.microsoft.com/beta/conditionalAccess/policies, and use the Request Body from the provided templates one at a time. Remember to change the Display Name of the policy before you click Post, and either replace Object Id's for excluded accounts, or remove this value from the Request Body if you want to manually add them in the Portal GUI at a later time.

### Deploy the custom templates using PowerShell (coming soon)

To deploy using PowerShell and Graph, do the following....
