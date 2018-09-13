#!/usr/bin/perl

require '../lib/ascii_draw.pm';
require '../lib/common.pm';

# returns:
# all_so - reference to hash
sub query_all_so {
    my @all_pkgs = common::query_all_pkg();
    my $all_so = {};

    foreach my $pkg (@all_pkgs)
    {
        print "query pkg:$pkg\n";

        my @rs = common::query_pkg_exe_files($pkg);
        
        foreach my $f (@{$rs[0]})
        {
            ${$all_so}{$f} = 1;
        }
    }

    return $all_so;
}

# parameters:
# all_so - reference to hash
# dep - reference to hash of hash
#
sub build_so_dep {
    my $all_so = shift;
    my $dep = shift;

    my $queue = [];

    foreach my $so (keys %$all_so)
    {
        push @$queue, ($so);
    }

    while ($#{$queue} != -1)
    {
        my $file_path = pop @$queue;

        next if defined ${$dep}{$file_path};

        my @rs = common::query_dep_files($file_path);

        ${$dep}{$file_path} = {
            "deps" => $rs[0],
            "desc" => "",
        };

        foreach my $i (@{$rs[0]})
        {
            if ((defined ${$dep}{$i}) or 
                (defined ${$all_so}{$i}))
            {
                next;
            }
            else
            {
                push @$queue, ($i);
            }
        }
    }
}

sub draw_so_dep {
    my @rs = query_all_so();
    my $dep = {};

    build_so_dep($rs[0], $dep);

    ascii_draw::draw_dep_graph($dep, "../data/so_result.txt");
}

#-------- test suite --------
sub test_query_all_so {
    my @rs = query_all_so();

    my @k = keys %{$rs[0]};
    my $n = $#k;
    print "total $n so:\n";
    foreach my $so (keys %{$rs[0]})
    {
        print "$so\n";
    }
}

sub test_build_so_dep {
    my @rs = query_all_so();

    my $dep = {};

    build_so_dep($rs[0], $dep);

    my @k = keys %$dep;
    my $n = $#k;

    print "total $n files\n";

    foreach my $i (keys %$dep)
    {
        print "file $i deps on:\n";
        my $value = ${${$dep}{$i}}{"deps"};
        foreach my $node (@$value)
        {
            print "$node\n";
        }
    }
}

#test_query_all_so();
#test_build_so_dep();

#-------- test suite --------
draw_so_dep();

