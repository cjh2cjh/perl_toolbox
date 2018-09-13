#!/usr/bin/perl

require '../lib/ascii_draw.pm';
require '../lib/common.pm';

# parameters:
# pkg_name - string
#
# returns:
# pkg_info - reference to hash
#
sub query_pkg_info {
    my $pkg_name = shift;

    my $s = `rpm --info -q $pkg_name`;

    my @summary = $s =~ m/^Summary\s*:\s*(.*)$/m;
    my @desc = $s =~ m/Description\s*:[\s\n]*(.*)/s;
    
    return if $#summary == -1;

    return {
        "summary" => $summary[0],
        "desc" => $desc[0],
    };
}

# parameters:
# file_path - target file path
#
# returns:
# pkg_name
sub query_belonging_pkg {
    my $file_path = shift;

    my $rs = `rpm -qf $file_path`;
    $rs =~ s/\n//;
    # containning space means error has been occured
    return if $rs =~ m/\s/;
    return $rs;
}

# parameters:
# pkg_name - target rpm package
# dep - reference to hash of hash, representing the dependency
#       graph.
sub build_pkg_dep {
    my $pkg_name = shift;
    my $dep = shift;

    my @info = query_pkg_info($pkg_name);

    if ($#info == -1)
    {
        print "package $pkg_name does not exist";
        return;
    }

    ${$dep}{$pkg_name} = {
        "deps" => [],
        "desc" => ${$info[0]}{"summary"},
    };

    my @exe_files = common::query_pkg_exe_files($pkg_name);

    my %dep_files = ();

    foreach my $file (@{$exe_files[0]})
    {
        my @rs = common::query_dep_files($file);

        #print "$file, deps on:\n";
        #print "$_\n" foreach @{$rs[0]};

        foreach my $f (@{$rs[0]})
        {
            $dep_files{$f} = 1;
        }
    }

    my %dep_pkgs = ();
    foreach my $file (keys %dep_files)
    {
        my @p = query_belonging_pkg($file);
        next if $#p == -1;
        next if $p[0] eq $pkg_name;

        #print "$file, $p[0]\n";
        $dep_pkgs{$p[0]} = 1
    }

    foreach my $pkg (keys %dep_pkgs)
    {
        push @{${${$dep}{$pkg_name}}{"deps"}}, ($pkg);
    }

    #print "deps on:\n";
    #print "$_\n" foreach keys %dep_pkgs;
}

sub build_dep {
    my $dep = {};
    my @rs = common::query_all_pkg();

    print "total $#rs packages\n";
    
    my $i = 1;

    foreach my $pkg (@rs) 
    {
        print "$i. building dependency for pkg:$pkg\n";
        build_pkg_dep($pkg, $dep);

        $i = $i + 1;
    }

    ascii_draw::draw_dep_graph($dep, "../data/rpm_result.txt");
}

#-------- test suite --------
sub test_query_all_pkg {
    my @rs = common::query_all_pkg();
    print "$_\n" foreach @rs;
}

sub test_query_pkg_info {
    my @rs = query_pkg_info("lvm2-2.02.177-4.el7.x86_64");
    print "summary:" . ${$rs[0]}{"summary"} . "\n";
    print "desc:" . ${$rs[0]}{"desc"} . "\n";
}

sub test_query_pkg_exe_files {
    my @exe_files = common::query_pkg_exe_files(
        "lvm2-2.02.177-4.el7.x86_64"
    );
    print "$_\n" foreach @{$exe_files[0]};
}

sub test_query_belonging_pkg {
    my @p = query_belonging_pkg("/usr/sbin/lvm");
    print $p[0] . "\n";
}

sub test_query_dep_files {
    my @rs = common::query_dep_files("/usr/sbin/lvm");
    print "$_\n" foreach @{$rs[0]};
}

sub test_build_pkg_dep {
    my $dep = {};
    #build_pkg_dep("lvm2-2.02.177-4.el7.x86_64", $dep);
    build_pkg_dep("glibc-2.17-222.el7.x86_64", $dep);
    #build_pkg_dep("nss-softokn-freebl-3.34.0-2.el7.x86_64", $dep);

    foreach my $name (keys %$dep)
    {
        print "pkg:$name\n";

        my $value = ${$dep}{$name};
        my $summary = ${$value}{"desc"};
        print "summary:$summary\n";

        my $deps = ${$value}{"deps"};
        foreach my $p (@$deps)
        {
            print "dep:$p\n";
        }
    }
}

#test_query_all_pkg();
#test_query_pkg_info();
#test_query_belonging_pkg();
#test_query_pkg_exe_files();
#test_query_dep_files();
#test_build_pkg_dep();

#-------- test suite --------

build_dep();


