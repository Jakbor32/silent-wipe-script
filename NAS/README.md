## NAS configuration

To set up automatic backup of group email accounts, follow these steps. My version of NAS is shown in the photo below:

## ![Photo showing the NAS version](version.png)

Go to the package center and select Active Backup for Microsoft 365. If it is not installed, please do so.

## ![Screenshot of the app installation in the package center](app_name.png)

Go to the application, select the task list, and select a new task to create a backup.

## ![Screenshot showing how to create a new backup task](create_backup.png)

Name the backup with your own name, then search for the group you created in the domain, select it, and if necessary, activate Active Backup for Microsoft 365 Portal. Selecting this option allows users without admin privileges to independently restore or export their data from the backup in the Active Backup for Microsoft 365 portal.

![Field to add a task name in the backup application](task_name.png)
![Selecting a group for backup in the application](select_group.png)

---

Select create a backup task to connect the backup application to your domain and generate an application certificate.

![Selecting the backup task type](task_type.png)
![Creating a certificate for the backup application](create_certificate.png)

---

After entering the certificate password and continuing, you should be prompted to log in to 365 and asked to grant permissions to NAS. Accept, and the application will be registered in your domain as trusted.

![Prompt to accept permissions for NAS in Microsoft 365](permissions.png)

## ![Confirmation screen for accepted permissions](permissions2.png)

Don't select anything here. We only need a backup of this one group, nothing else.

## ![Selecting account type for backup, with no additional selections](account_type.png)

Set the scheduler to perform a backup every Monday, the script runs every month, or the setting can be changed, so there is no need to perform backups every day.

## ![Setting the backup schedule in the application](schedule.png)

This is what the finished backup looks like.

![Summary screen showing the completed backup task](summary.png)
