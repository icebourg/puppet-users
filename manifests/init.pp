#
# Manages users and their keys
#
# Allows you to set up a new user account.
# Note that you should send any ssh keys you have as an array of just the
# key (no comment or security type). Unfortunately, because of the lack of
# loops in puppet, all ssh keys must be of the same type (rsa or dss)
# You can't have some keys one type and other keys another type
#

class user {
  
  # script to set a random password for a user
  file { "/usr/bin/setuserpassword":
    ensure  => file,
    source  => "puppet://$servername/modules/users/setuserpassword.sh",
    mode    => 755,
  }

  define manage (
    $email,
    $uid,
    $username = $title,
    $ensure   = "present",
    $set_password = true,
    $ssh_keys = [],
    $key_type = "ssh-rsa",
    $shell    = '/bin/bash',
    $home     = "/home/$username",
    $sudoer   = false,
    $root_ssh = false,
    $groups   = [],
    $managehome = true
  ) {

    user { $username:
      ensure  => $ensure,
      comment => $email,
      home    => $home,
      shell   => $shell,
      uid     => $uid,
      groups  => $groups,
      managehome  => $managehome,
    }

    # should we add the user to the sudo group?
    if $sudoer {
      include security::sudo

      add_user_to_sudo { $username:
        require => User[$username],
      }
    }

    if $ssh_keys {
      user::ssh_keys { $ssh_keys:
        username  => $username,
        key_type  => $key_type,
      }
    }

    if $root_ssh {
      user::root_ssh_keys { $ssh_keys:
        key_type  => $key_type,
      }
    }

    if $set_password {
      
      exec { "/usr/bin/setuserpassword $username":
        path        => "/bin:/usr/bin",
        refreshonly => true,
        subscribe   => User[$username],
        unless      => "cat /etc/shadow | grep $username| cut -f 2 -d : | grep -v '!'",
        require     => User[$username]
      }
    }
  }

  define ssh_keys ($username, $key_type) {

    $ssh_key = $title

    # we need a unique title for ssh_authorized_key, so md5 the actual key to
    # give it to us
    $ssh_md5 = md5($ssh_key)

    ssh_authorized_key { "ssh_key_${username}_${$ssh_md5}":
      ensure  => $ensure,
      key     => "$ssh_key",
      type    => "$key_type",
      user    => $username,
    }

  }

  define root_ssh_keys ($key_type) {
    $username = "root"
    $ssh_key = $title

    # we need a unique title for ssh_authorized_key, so md5 the actual key to give it to us
    $ssh_md5 = md5($ssh_key)

    ssh_authorized_key { "ssh_key_${username}_${$ssh_md5}":
      ensure  => $ensure,
      key     => "$ssh_key",
      type    => "$key_type",
      user    => $username,
    }
  }
}
