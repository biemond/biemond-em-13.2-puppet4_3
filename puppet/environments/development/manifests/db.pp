node 'emdb.example.com'  {
  include oradb_os
  include oradb_12c
  include oradb_init
  # include oradb_em_agent
}

# operating settings for Database & Middleware
class oradb_os {

# will not work with a VM with FS as btrfs 
#  swap_file::files { 'swap_file':
#    ensure       => present,
#    swapfilesize => '8 GB',
#    swapfile     => '/data/swap.1' 
#  }

  # set the tmpfs
  mount { '/dev/shm':
    ensure      => present,
    atboot      => true,
    device      => 'tmpfs',
    fstype      => 'tmpfs',
    options     => 'size=3500m',
  }

  $host_instances = lookup('hosts', {})
  create_resources('host',$host_instances)

  service { iptables:
    enable    => false,
    ensure    => false,
    hasstatus => true,
  }

  $groups = ['oinstall','dba' ,'oper' ]

  group { $groups :
    ensure      => present,
  }

  user { 'oracle' :
    ensure      => present,
    uid         => 500,
    gid         => 'oinstall',
    groups      => $groups,
    shell       => '/bin/bash',
    password    => '$1$DSJ51vh6$4XzzwyIOk6Bi/54kglGk3.',
    home        => "/home/oracle",
    comment     => "This user oracle was created by Puppet",
    require     => Group[$groups],
    managehome  => true,
  }

  $install = ['binutils.x86_64', 'compat-libstdc++-33.x86_64', 'glibc.x86_64','ksh.x86_64','libaio.x86_64',
              'libgcc.x86_64', 'libstdc++.x86_64', 'make.x86_64','compat-libcap1.x86_64', 'gcc.x86_64',
              'gcc-c++.x86_64','glibc-devel.x86_64','libaio-devel.x86_64','libstdc++-devel.x86_64',
              'sysstat.x86_64','unixODBC-devel','glibc.i686','libXext.x86_64','libXtst.x86_64','xorg-x11-xauth']


  package { $install:
    ensure  => present,
  }

  class { 'limits':
    config => {
                '*'       => { 'nofile'  => { soft => '2048'   , hard => '8192',   },},
                'oracle'  => { 'nofile'  => { soft => '65536'  , hard => '65536',  },
                                'nproc'  => { soft => '2048'   , hard => '16384',  },
                                'stack'  => { soft => '10240'  ,},},
                },
    use_hiera => false,
  }

  sysctl { 'kernel.msgmnb':                 ensure => 'present', permanent => 'yes', value => '65536',}
  sysctl { 'kernel.msgmax':                 ensure => 'present', permanent => 'yes', value => '65536',}
  sysctl { 'kernel.shmmax':                 ensure => 'present', permanent => 'yes', value => '2588483584',}
  sysctl { 'kernel.shmall':                 ensure => 'present', permanent => 'yes', value => '2097152',}
  sysctl { 'fs.file-max':                   ensure => 'present', permanent => 'yes', value => '6815744',}
  sysctl { 'net.ipv4.tcp_keepalive_time':   ensure => 'present', permanent => 'yes', value => '1800',}
  sysctl { 'net.ipv4.tcp_keepalive_intvl':  ensure => 'present', permanent => 'yes', value => '30',}
  sysctl { 'net.ipv4.tcp_keepalive_probes': ensure => 'present', permanent => 'yes', value => '5',}
  sysctl { 'net.ipv4.tcp_fin_timeout':      ensure => 'present', permanent => 'yes', value => '30',}
  sysctl { 'kernel.shmmni':                 ensure => 'present', permanent => 'yes', value => '4096', }
  sysctl { 'fs.aio-max-nr':                 ensure => 'present', permanent => 'yes', value => '1048576',}
  sysctl { 'kernel.sem':                    ensure => 'present', permanent => 'yes', value => '250 32000 100 128',}
  sysctl { 'net.ipv4.ip_local_port_range':  ensure => 'present', permanent => 'yes', value => '9000 65500',}
  sysctl { 'net.core.rmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
  sysctl { 'net.core.rmem_max':             ensure => 'present', permanent => 'yes', value => '4194304', }
  sysctl { 'net.core.wmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
  sysctl { 'net.core.wmem_max':             ensure => 'present', permanent => 'yes', value => '1048576',}
}

class oradb_12c {
  require oradb_os

    oradb::installdb{ 'db_linux-x64':
      version                   => '12.1.0.2',
      file                      => 'linuxamd64_12102_database',
      database_type             => 'EE',
      oracle_base               => lookup('oracle_base_dir'),
      oracle_home               => lookup('oracle_home_dir'),
      remote_file               => false,
      download_dir              => lookup('oracle_download_dir'),
      puppet_download_mnt_point => lookup('oracle_source'),
    }

    oradb::net{ 'config net8':
      oracle_home  => lookup('oracle_home_dir'),
      version      => '12.1',
      require      => Oradb::Installdb['db_linux-x64'],
    }

    db_listener{ 'startlistener':
      ensure          => 'running',  # running|start|abort|stop
      oracle_base_dir => lookup('oracle_base_dir'),
      oracle_home_dir => lookup('oracle_home_dir'),
      require         => Oradb::Net['config net8'],
    }

    oradb::database{ 'oraDb':
      oracle_base               => lookup('oracle_base_dir'),
      oracle_home               => lookup('oracle_home_dir'),
      version                   => '12.1',
      download_dir             => lookup('oracle_download_dir'),
      action                   => 'create',
      db_name                  => lookup('oracle_database_name'),
      db_domain                => lookup('oracle_database_domain_name'),
      sys_password             => lookup('oracle_database_sys_password'),
      system_password          => lookup('oracle_database_system_password'),
      data_file_destination     => "/oracle/oradata",
      recovery_area_destination => "/oracle/flash_recovery_area",
      character_set            => "AL32UTF8",
      nationalcharacter_set    => "UTF8",
      em_configuration         => 'NONE',
      memory_total             => 2500,
      sample_schema            => 'FALSE',
      database_type            => "MULTIPURPOSE",
      require                  => Db_Listener['startlistener'],
    }

    oradb::dbactions{ 'start oraDb':
      oracle_home              => lookup('oracle_home_dir'),
      user                    => lookup('oracle_os_user'),
      group                   => lookup('oracle_os_group'),
      action                  => 'start',
      db_name                  => lookup('oracle_database_name'),
      require                 => Oradb::Database['oraDb'],
    }

    oradb::autostartdatabase{ 'autostart oracle':
      oracle_home              => lookup('oracle_home_dir'),
      user                    => lookup('oracle_os_user'),
      db_name                  => lookup('oracle_database_name'),
      require                 => Oradb::Dbactions['start oraDb'],
    }

}

class oradb_init {
  require oradb_12c

  ora_init_param{ 'SPFILE/optimizer_adaptive_features@emrepos':
    ensure => 'present',
    value  => 'FALSE',
  }

  ora_init_param{ 'SPFILE/OPEN_CURSORS@emrepos':
    ensure => 'present',
    value  => '601',
  }

  ora_init_param{ 'SPFILE/processes@emrepos':
    ensure => 'present',
    value  => '1000',
  }

  ora_init_param{'SPFILE/job_queue_processes@emrepos':
    ensure  => present,
    value   => '20',
  }

  ora_init_param{'SPFILE/session_cached_cursors@emrepos':
    ensure  => present,
    value   => '200',
  }

  ora_init_param{'SPFILE/db_securefile@emrepos':
    ensure  => present,
    value   => 'PERMITTED',
  }

  # ora_init_param{'SPFILE/memory_target@emrepos':
  #   ensure  => present,
  #   value   => '3000M',
  # }

  ora_init_param { 'SPFILE/PGA_AGGREGATE_TARGET@emrepos':
    ensure  => 'present',
    value   => '1G',
    # require => Ora_init_param['SPFILE/memory_target@emrepos'],
  }

  ora_init_param { 'SPFILE/SGA_TARGET@emrepos':
    ensure  => 'present',
    value   => '1200M',
    # require => Ora_init_param['SPFILE/memory_target@emrepos'],
  }
  ora_init_param { 'SPFILE/SHARED_POOL_SIZE@emrepos':
    ensure  => 'present',
    value   => '600M',
    # require => Ora_init_param['SPFILE/memory_target@emrepos'],
  }

  db_control{'emrepos restart':
    ensure                  => 'running', #running|start|abort|stop
    instance_name           => lookup('oracle_database_name'),
    oracle_product_home_dir => lookup('oracle_home_dir'),
    os_user                 => lookup('oracle_os_user'),
    refreshonly             => true,
    subscribe               => [Ora_init_param['SPFILE/OPEN_CURSORS@emrepos'],
                                Ora_init_param['SPFILE/processes@emrepos'],
                                Ora_init_param['SPFILE/job_queue_processes@emrepos'],
                                Ora_init_param['SPFILE/session_cached_cursors@emrepos'],
                                Ora_init_param['SPFILE/db_securefile@emrepos'],
                                Ora_init_param['SPFILE/SGA_TARGET@emrepos'],
                                Ora_init_param['SPFILE/SHARED_POOL_SIZE@emrepos'],
                                Ora_init_param['SPFILE/PGA_AGGREGATE_TARGET@emrepos'],
                                Ora_init_param['SPFILE/optimizer_adaptive_features@emrepos'],
                                ],
  }

}

class oradb_em_agent {

    # oradb::rcu{'DEV_PS6':
    #   rcu_file       => 'ofm_rcu_linux_11.1.1.7.0_64_disk1_1of1.zip',
    #   product        => 'soasuite',
    #   version        => '11.1.1.7',
    #   oracle_home    => lookup('oracle_home_dir'),
    #   action         => 'create',
    #   db_server      => 'emdb.example.com:1521',
    #   db_service     => 'emrepos.example.com',
    #   sys_password   => 'Welcome01',
    #   schema_prefix  => 'DEV',
    #   repos_password => 'Welcome02',
    #   puppet_download_mnt_point => lookup('oracle_source'),
    # }


  oradb::installem_agent{ 'em13200_agent':
    version                     => '13.2.0.0',
    source                      => 'https://10.10.10.25:7799/em/install/getAgentImage',
    install_type                => 'agentPull',
    install_platform            => 'Linux x86-64',
    install_version             => '13.2.0.0.0',
    oracle_base_dir             => '/oracle',
    agent_base_dir              => '/oracle/product/13.2/agent',
    agent_instance_home_dir     => '/oracle/product/13.2/agent/agent_inst',
    sysman_user                 => 'sysman',
    sysman_password             => 'Welcome01',
    agent_registration_password => 'Welcome01',
    agent_port                  => 1830,
    oms_host                    => '10.10.10.25',
    oms_port                    => 7799,
    em_upload_port              => 4889,
    oracle_hostname             => 'emdb.example.com',
    user                        => 'oracle',
    group                       => 'dba',
    download_dir                => '/var/tmp/install',
    log_output                  => true,
  }

  # oradb::installem_agent{ 'em12105_agent2':
  #   version                     => '12.1.0.5',
  #   source                      => '/var/tmp/install/agent.zip',
  #   install_type                => 'agentDeploy',
  #   oracle_base_dir             => '/oracle',
  #   agent_base_dir              => '/oracle/product/12.1/agent2',
  #   agent_instance_home_dir     => '/oracle/product/12.1/agent2/agent_inst',
  #   agent_registration_password => 'Welcome01',
  #   agent_port                  => 1832,
  #   oms_host                    => '10.10.10.25',
  #   em_upload_port              => 4903,
  #   user                        => 'oracle',
  #   group                       => 'dba',
  #   download_dir                => '/var/tmp/install',
  #   log_output                  => true,
  # }

}