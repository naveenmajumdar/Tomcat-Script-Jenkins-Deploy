#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use File::Basename;
use Cwd;

my $tomat_manager = $ARGV[0];
my $tomcat_admin = $ARGV[1];
my $tomcat_passwd = $ARGV[2];
my $war_file = $ARGV[3];
my $path = $ARGV[4]; # Added by Allen to use Context path as a parameter

my $dir = getcwd;
my $tmp_fldr = "$dir/tmpdownload";

print "$tmp_fldr\n";

my $version = &find_tomcat_version($tomat_manager,$tomcat_admin,$tomcat_passwd);


if($version > 6) {
   $tomat_manager = "$tomat_manager/text";
}

&download_war($war_file);

if (!$path){

my $path = &find_context_path(basename($war_file));

if(!$path) {
   $path = find_path($war_file);
}
}

&stop($tomat_manager,$tomcat_admin,$tomcat_passwd,$path);

&undeploy($tomat_manager,$tomcat_admin,$tomcat_passwd,$path);

&deploy($tomat_manager,$tomcat_admin,$tomcat_passwd,$path,basename($war_file));

&start($tomat_manager,$tomcat_admin,$tomcat_passwd,$path);

sub stop {
    my ($manager_url,$manager_user,$manager_pass,$app_path) = @_;
    my $stop_cmd = "curl $tomcat_admin:$tomcat_passwd\@$manager_url/stop?path=$app_path";
    my $response = `$stop_cmd`;

    print $response;

}

sub start {
    my ($manager_url,$manager_user,$manager_pass,$app_path) = @_;
    my $start_cmd = "curl $tomcat_admin:$tomcat_passwd\@$manager_url/start?path=$app_path";
    my $response = `$start_cmd`;

    print $response;
}

sub undeploy {

    my ($manager_url,$manager_user,$manager_pass,$app_path) = @_;

    my $undeploy_url = "curl $tomcat_admin:$tomcat_passwd\@$manager_url/undeploy?path=$app_path";

    my $retry_counter = 1;
    my $response;

    while ($retry_counter <= 3 ) {
         print " Attempt number $retry_counter to undeploy the application \n" ;
         $response = `$undeploy_url`;
         print $response;
         if ( index($response, "FAIL") == -1 ){
                last;
                }
         print " Retrying in 5 seconds \n";
         sleep 5;
         $retry_counter += 1;
        }


}

sub deploy {

    my ($manager_url,$manager_user,$manager_pass,$app_path, $war_file) = @_;

    my $deploy_url = "curl -T $tmp_fldr/$war_file $tomcat_admin:$tomcat_passwd\@$manager_url/deploy?path=$app_path&update=true";

    my $response = `$deploy_url`;
    if($response =~ m/Fail/ig) {
      print "here";
      die $response;
      exit 1;
    }

    print $response;
}

sub download_war {
     my $war_file  = shift;
     if(!-e $tmp_fldr) {
       mkdir $tmp_fldr;
     }
#     my $cmd = "wget $war_file -P $tmp_fldr";
     my $cmd = "cp $war_file  $tmp_fldr";
     `$cmd`;
     return;
}

sub find_tomcat_version {
   my ($manager_url,$manager_user,$manager_pass) = @_;

   my $version6_url = $manager_url ."/serverinfo";
   my $version7_url = $manager_url ."/text/serverinfo";

   my $cmd = "curl $manager_user:$manager_pass\@$version6_url | grep 'Tomcat Version' | awk -F/ '{print \$2}'";

   my $output = `$cmd`;

   if(!$output) {
     my $cmd = "curl $manager_user:$manager_pass\@$version7_url| grep 'Tomcat Version' | awk -F/ '{print \$2}'";
     $output = `$cmd`;
   }
   if(!$output){
        print "Failed to get version of Server. This may mean that server is not running\n";
        exit 1;
   }
   chomp $output;
   my $version = ((split(/\./,$output))[0] > 6)?7:6;
   print "Version is $version";
   return $version;
}

sub find_context_path {
   my $war_file = shift;
   my $context;
   my $cmd = "cd $tmp_fldr; jar -xvf $war_file; cd $dir";
   `$cmd`;

   my $grp_cmd="grep -i path= $tmp_fldr/META-INF/context.xml";

   my $str = `$grp_cmd`;
   print "$str\n";

  if($str =~ m/^<(.*)path="(.*?)"(.*)>$/ig) {
     $context = $2;
     print "$context\n";
  }
   return $context;
}

sub find_path {
   my $war_file = shift;

   my $file_name = basename($war_file);

   $file_name = (split(/\./,$file_name))[0];

   return "/$file_name";

}

#END {
#   my $cmd = "rm -rf $tmp_fldr";
#  `$cmd`;
#}
