Please read these instructions carefully to make sure the VM you downloaded starts up properly, so you can use the installed products without problems.

VM version : 

Installed software :

JDK : 1.7 version 79
Oracle : 11.2.0 XE
Interstage BPM : 11.3.1 build 550
K-mail : version 3/1/2016
JBoss : 6.1
Node JS Chat Client
SSOFI Open ID updated 3/1/2016
Angular Adapter updated 10/12/2016
Quebec Demo updated 8/14/2016



Extracting the files :

After downloading all .7z files, highlight all of them and right click on them to select 7-zip > Extract Files.
A new window will pop up, please select the location where you would like your VM to be created, and click 'OK'.
After a short amount of time, you will see a new folder ( interstagedemov52 ) inside the folder you selected above, with several files in it. Remember the location of this folder, as you will need it later.


Starting the VM :

To start the VM, please start VMWare Player on your own machine.
Select 'Open a Virtual Machine' and browse to the the folder created before when you extracted the files.
Select the .vmx file shown inside that folder and click 'Open'. The VMWare player window will show some of the details related to this VM. Note that it will take up 2Gb of RAM when started. If you want to allocate more memory to the VM, click
'Edit virtual machine settings' and make the changes required, then click 'OK'.
Start the VM by clicking 'Play Virtual Machine', and wait for the Fujitsu Welcome screen to show up after a few minutes. (If the startup procedure shows a window asking if you moved or copied the VM, select 'I Copied It'.)

Once this window shows up, several details you will need will be shown, such as the username / password, and the VM's hostname (interstagedemo) and IP address.


ATTENTION !!!!  --------------------------------------------------------------------------------------------------------------------------


To use all products installed, you must use the hostname. Failure to follow the next steps will cause some of the products installed not to function at all !!!
By default, your hosting machine (e.g. laptop) will not be able to use the VM's hostname, therefore you MUST follow the steps below next :

- Using the Windows Explorer, find and open the file : C:\Windows\System32\drivers\etc\hosts
- Add a new line at the bottom looking like this : 192.168.174.143 interstagedemo
- Save and exit the file.

(Note : the IP address in this case is an example. Your IP address is likely different (see the Fujitsu Welcome screen shown in VMWare Player). Make sure to use your VM's IP address !!!)

------------------------------------------------------------------------------------------------------------------------------------------

Using the product :

Now that the VM is up and running, please open up the browser on your own machine, and use http://interstagedemo to access the product.
The web page contains all the links to the various products you need.

If you would like, you can use the following URL's directly from your browser to access individual products, allthough the aforementioned web page will give you this option as well :

Interstage BPM :

http://interstagedemo:49950/console/default/getDashboard.page

Username : admin
Password : Fujitsu1

Interstage BPM Tenant Manager :

http://interstagedemo:49950/console/TenantManager.page

Username : admin
Password : Fujitsu1

JBoss console :

http://interstagedemo:9990/console/App.html

Username : admin
Password : Fujitsu.1

KMail :

http://interstagedemo:49950/kMail/

Agile Adapter :

http://interstagedemo:49950/aa/

ssofi provider :

http://interstagedemo:49950/ssofi/

Oracle / DB :

http://interstagedemo:8880

Username : SYSTEM
Password : Fujitsu1


File locations:

JBoss / Interstage BPM :     /opt/jboss-eap-6.1/
KMail :    /opt/kMail
Agile Adapter :    /opt/aa
ssofi :    /opt/ssofi
Oracle :    /u01/app/oracle