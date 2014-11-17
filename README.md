# FHLB Member Portal

# Local Development

We use [Foreman](https://github.com/ddollar/foreman) to manage launching the various applications defined in this repository. Local environment configuration is supplied via [dotenv](https://github.com/bkeepers/dotenv). You will want to start with a copy of the example environment defined in `.env.example`.

We use [Vagrant](https://www.vagrantup.com/) to manage a VM that provides all the needed services for the applications. You will need to make sure your Vagrant VM is running before you try and launch the application. Note that the VM requires 2 GB of RAM and a dedicated CPU.

## Prerequisites

* [RVM](http://rvm.io/) installed.
* Ruby 2.1.2 (or whatever is currently called out in `.ruby-version`) installed via RVM. If you `cd` into the working copy and don't have the right Ruby installed, RVM will suggest that you install it. Complete the installation before moving forward. You will want to close the shell session and start a new one after installing Ruby.
* [VirtualBox](https://www.virtualbox.org/) installed.
* [Vagrant](https://www.vagrantup.com/) installed.
* [Oracle Instant Client](http://www.oracle.com/technetwork/database/features/instant-client/index-097480.html) 11g installed, along with the accompanying SDK headers (separate download). See below for details.
* [Oracle DB Express 11g Release 2](http://www.oracle.com/technetwork/database/database-technologies/express-edition/downloads/index-083047.html) for Linux (RPM) downloaded. You just need the file, installation will be handled by Vagrant.

### Oracle Instant Client

Oracle Instant Client is needed for the Oracle DB adapter used by ActiveRecord. To install, follow these steps (POSIX systems):

1. [Download](http://www.oracle.com/technetwork/database/features/instant-client/index-097480.html) the Oracle Instant Client (11g release 2, currently 11.2.0.4.0) for your platform, as well as the SDK package and SQL*Plus package for your platform (found on the same page).
2. Extract all three zip files into the same directory.
3. Place that directory somewhere in your system in a path that **contains no spaces**. If there are any spaces anywhere in the path the gem install will not work. You will get an obtuse error saying that `DYLD_LIBRARY_PATH` needs to be defined.
4. `cd` into the Oracle Instant Client directory in your shell and run `ln -s libclntsh.dylib.11.1 libclntsh.dylib` (OS X) or `ln -s libclntsh.so.11.1 libclntsh.so` (Linux), which creates a needed symlink.
5. Open `~/.bash_profile` (or `~/.bashrc` depending on your OS/shell) and add the following lines (replacing `YOUR_PATH` with the absolute path to the Oracle Instant Client directory):

   OS X:
   ```
   export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:YOUR_PATH
   export NLS_LANG="AMERICAN_AMERICA.UTF8"
   export PATH=$PATH:YOUR_PATH
   ```

   Linux:
   ```
   export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:YOUR_PATH
   export NLS_LANG="AMERICAN_AMERICA.UTF8"
   export PATH=$PATH:YOUR_PATH
   ```

6. `source ~/.bashrc` to load the new environment variables into your current shell.


## Setup Instructions

Follow these steps to get up and running:

1. `bundle install`
2. `cp .env.example .env`
3. Edit `.env` and set `SECRET_KEY_BASE` to some long cryptographic string. If you change this, old cookies will become unusable.
4. `export ORACLE_INSTALLER=PATH_TO_INSTALLER` with `PATH_TO_INSTALLER` replaced with the path to the directory containing the Oracle DB 11g RPM.
5. `vagrant up` -- This will take 15-30 minutes, and will generate a `.deb` version of the 11g RPM in the same directory was the RPM. Save this file if you want to be able to rebuild your Vagrant system more quickly.
6. `rake db:setup` -- You will be asked for the SYSTEM password twice, which is `password`.
7. `foreman start`
8. Navigate over to [http://localhost:3000](http://localhost:3000)

# .env Details

This is a summary of the options supported in our .env files:

* `PORT`: The base port for foreman.
* `SECRET_KEY_BASE`: The secret key used to sign cookies for this environment. You can get a value from [Fourmilab](https://www.fourmilab.ch/cgi-bin/Hotbits?nbytes=128&fmt=password&npass=1&lpass=30&pwtype=2).
* `DATABASE_USERNAME`: The username to use to connect to the DB (overrides the values found in database.yml).
* `DATABASE_PASSWORD`: The password to use to connect to the DB (overrides the values found in database.yml).
* `SAUCE_USERNAME`: The username of the SauceLabs user, used when cucumber tests are run via SauceLabs.
* `SAUCE_ACCESS_KEY`: The access key associated with the SauceLabs user (`SAUCE_USERNAME`). Only used when running cucumber tests via SauceLabs.
