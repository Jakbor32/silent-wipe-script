# Azure App Registration for SharePoint & Microsoft Graph and Group Creation


## 1. Create a New Group

Navigate to **Groups** in the Azure portal, then select **New group** to create a microsoft 365 group for your application.

![Screenshot showing the Azure portal Groups section with the 'New group' button highlighted.](create_new_group_azure.png)


## 2. Create a New App Registration

_App registration is performed in Microsoft Entra ID (formerly Azure AD), available at [portal.azure.com](https://portal.azure.com)._
_Search for "App registrations" in the portal, as all application configuration takes place in Entra ID._

Go to **App registrations** and click **New registration**.

![Screenshot of the App registrations page in Azure, highlighting the 'New registration' button.](adding_new_app.png)

After registration, copy the **Client ID** and **Tenant ID** from the application overview page. These values are required for authentication in PowerShell scripts.

![Screenshot showing where to find the Client ID and Tenant ID in the app registration overview.](client_ID__tenant_ID.png)

---

Next, configure authentication for your app. Go to the **Authentication** tab and click **Add a platform**.

![Screenshot of the Authentication tab with the 'Add a platform' button highlighted.](authentication.png)

Choose the appropriate platform for your application (e.g., Web, Mobile, Desktop).

![Screenshot showing the selection of a platform type for authentication.](platform.png)

After selecting a platform, configure the redirect URI.

![Screenshot of the platform configuration page, showing where to enter redirect URIs.](platform_2.png)

## 3. Configure API Permissions

### For SharePoint

Go to the **API permissions** tab and click **Add a permission**.

![Screenshot of the API permissions tab with the 'Add a permission' button highlighted.](api_permissions.png)

Select **SharePoint** from the list of available APIs.

![Screenshot showing the SharePoint API selection in the permissions dialog.](sharepoint_request.png)

Choose **Delegated permissions** and select the required permissions for your app (e.g., `AllSites.FullControl`).

![Screenshot of the delegated permissions selection for SharePoint.](delegated_sharepoint.png)

Review the list of selected SharePoint permissions.

![Screenshot showing the list of assigned SharePoint permissions.](sharepoint_permissions.png)

### For Microsoft Graph

Similarly, add permissions for Microsoft Graph.

![Screenshot showing the Microsoft Graph API selection.](graph_api.png)

Choose **Delegated permissions** and select the necessary permissions (e.g. `User.ReadWrite.All`).

![Screenshot of delegated permissions selection for Microsoft Graph.](delegated_graph.png)

Review the list of assigned Microsoft Graph permissions.

![Screenshot showing the list of assigned user permissions for Microsoft Graph.](user_permissions.png)
![Another screenshot showing additional user permissions.](user_permissions2.png)

## 4. Grant Admin Consent

After configuring permissions, click **Grant admin consent** to approve the permissions for your organization.

![Screenshot of the 'Grant admin consent' button in the API permissions tab.](grant_admin_consent.png)

Remove any unnecessary permissions to keep your app secure.

![Screenshot showing how to remove other permissions from the list.](remove_other_permissions.png)

## 5. Generate a Certificate

To enable secure authentication, generate a self-signed certificate using PowerShell. Open PowerShell and run the following commands:

```powershell
# Generate a self-signed certificate
$cert = New-SelfSignedCertificate `
    -Subject "CN=MyAppCert" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -KeyExportPolicy Exportable `
    -KeySpec Signature `
    -KeyLength 2048 `
    -Provider "Microsoft Enhanced Cryptographic Provider v1.0" `
    -NotAfter (Get-Date).AddYears(2)

# Export the public certificate (.cer)
Export-Certificate -Cert $cert -FilePath "C:\Path\To\YourAppName.cer"
```

This will create a certificate in your user certificate store and export the public part to a `.cer` file.

## 6. Add Certificate to App Registration

In your app registration, go to **Certificates & secrets**. Click **Upload certificate** and select your `.cer` file. After upload, note the **Thumbprint** value, which will be used for authentication.

![Screenshot of the Certificates & secrets tab with an uploaded certificate and thumbprint highlighted.](upload_certficate.png)

## 7. Copy the Data You Will Use in PowerShell

Make sure to copy and securely store the following values for use in your PowerShell scripts:

- **Thumbprint** (from the uploaded certificate)
- **Client ID** (from the app registration overview)
- **Tenant ID** (from the app registration overview)

---

**References:**

- [Microsoft: Register an application](https://learn.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app)
- [Microsoft: Certificates for authentication](https://learn.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal)


