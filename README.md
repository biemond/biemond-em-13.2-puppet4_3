## Oracle Enterprise Manager 13.2.0.0 for Puppet 4

### Software
- linuxamd64_12c_database_1of2.zip  ( 12.1.0.2 )
- linuxamd64_12c_database_2of2.zip
- em13200p1_linux64.bin   ( 13.2.0.0 )
- em13200p1_linux64-2.zip to em13200p1_linux64-7.zip

### Vagrant
Update the local path of the /software share in Vagrantfile to your own DB & EM software location

### EM DB steps
- vagrant up emdb

### EM App steps
- vagrant up emapp

### default urls
- Enterprise Manager Cloud Control URL: https://10.10.10.25:7802/em
- Admin Server URL: https://10.10.10.25:7102/console

### passwords
- em weblogic Welcome01
- em sysman Welcome01
- db sys Welcome01