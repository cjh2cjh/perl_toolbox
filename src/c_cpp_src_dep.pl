#!/usr/bin/perl

require '../lib/ascii_draw.pm';

# parameters:
# dir - the directory to query
# fileset - reference to array
sub query_files_recursive {
    my $dir = shift;
    my $fileset = shift;

    my @queue = ();

    push @queue, ($dir);

    while ($#queue != -1)
    {
        my $d = pop @queue;

        my $dh;
        if (!opendir($dh, $d))
        {
            print "failed to open dir, err:$!\n";
            next;
        }

        my @entries = readdir $dh;
        foreach my $i (@entries)
        {
            my $full_path = $d . "/" . $i;
            if (-f $full_path)
            {
                push @$fileset, ($full_path);
            }
            elsif (-d $full_path)
            {
                if ($i ne "." and $i ne "..")
                {
                    push @queue, ($full_path);
                }
            }
            else
            {
                print "entry:$full_path not file or dir\n";
            }
        }

        closedir $dh;
    }
}

# parameters:
# dirset - reference to array
# all_files - reference to hash
sub query_all_files {
    my $dirset = shift;
    my $all_files = shift;

    foreach my $dir (@$dirset)
    {
        my $fileset = [];
        query_files_recursive($dir, $fileset);

        foreach my $f (@$fileset)
        {
            if ($f =~ m/.*\.(c|cpp|h|hpp|inc)$/)
            {
                ${$all_files}{$f} = 1;
            }
        }
    }
}

# parameters:
# srcfile - file that includes
# dirset - include directory set
# file - included file name
#
# return:
# path - the guessed full included file path
sub guess_full_include_file {
    my $srcfile = shift;
    my $dirset = shift;
    my $file = shift;

    my @srcdir = split /\n/, `dirname $srcfile`;
    my $srcdir = $srcdir[0];
    my $full = $srcdir . "/" . $file;
    return $full if -f $full;

    foreach my $dir (@$dirset)
    {
        my $full = $dir . "/" . $file;
        return $full if (-f $full);
    }

    return $file;
}

# parameters:
# file - target file
# include_files - reference to array
sub extract_include_files {
    my $file = shift;
    my $include_files = shift;

    my $fd;
    unless (open($fd, "<", $file))
    {
        print "failed to open file:$file, err:$!\n";
        return;
    }

    my @lines = readline $fd;
    foreach my $line (@lines)
    {
        my @rs = $line =~ m/^[\s]*#include[\s]+<([^>]+)>.*/;
        if ($#rs == -1)
        {
            @rs = $line =~ m/^[\s]*#include[\s]+\"([^\"]+)\".*/;
            if ($#rs == -1)
            {
                next;
            }
        }

        push @$include_files, ($rs[0]);
    }

    close $fd;
}

# parameters:
# dirset - directory set
# dep - src files dependency
#
sub build_src_dep {
    my $dirset = shift;
    my $dep = shift;

    my $all_files = {};
    query_all_files($dirset, $all_files);

    my @queue = ();
    foreach my $f (keys %$all_files)
    {
        push @queue, ($f);
    }

    while ($#queue != -1)
    {
        my $f = pop @queue;

        next if defined ${$dep}{$f};

        my $include_files = [];
        extract_include_files($f, $include_files);

        foreach my $inc (@$include_files)
        {
            $inc = guess_full_include_file($f, $dirset, $inc);
        }

        foreach my $inc (@$include_files)
        {
            next if defined ${$all_files}{$inc} or 
                defined ${$dep}{$inc};

            push @queue, ($inc);
        }

        ${$dep}{$f} = {
            "deps" => $include_files,
            "desc" => "",
        };
    }
}

sub draw_src_dep {
    my $srcdir = "libgcc";
    $srcdir = $ARGV[0] if $#ARGV != -1;

    my @dirset = split /;/, $srcdir;

    my $dep = {};
 
    build_src_dep(\@dirset, $dep);

    ascii_draw::draw_dep_graph($dep, "../data/c_cpp_result.txt");
}

#-------- test suite --------

sub test_query_files_recursive {
    my $dir = "../../perl_opensource/ExtUtils-MakeMaker-7.34";
    my $fileset = [];

    query_files_recursive($dir, $fileset);

    foreach my $i (@$fileset)
    {
        print "$i\n";
    }
}

sub test_query_all_files {
    my $dirset = ["../data", "../lib", "libgcc"];
    my $all_files = {};

    query_all_files($dirset, $all_files);

    foreach my $i (keys %$all_files)
    {
        print "$i\n";
    }
}

sub test_extract_include_files {
    my $file = "libgcc/unwind-dw2.c";
    my $include_files = [];

    extract_include_files($file, $include_files);

    foreach my $i (@$include_files)
    {
        print "$i\n";
    }
}

sub test_guess_full_include_file {
    my $srcfile = "../data/so_result.txt";
    my $dirset = ["../data/"];
    my $file = "result.txt";

    my $full_file = guess_full_include_file($srcfile, $dirset, 
        $file);

    print $full_file;
}

sub test_build_src_dep {
    my $dirset = ["libgcc"];
    my $dep = {};

    build_src_dep($dirset, $dep);

    my @k = keys %$dep;
    my $n = $#k + 1;

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

#test_query_files_recursive();
#test_query_all_files();
#test_extract_include_files();
#test_guess_full_include_file();
#test_build_src_dep();

#-------- test suite --------

draw_src_dep();

