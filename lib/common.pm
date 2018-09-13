package common;

use strict;
use warnings;

BEGIN {
    require Exporter;

    our $VERSION = 1.00;
}

# returns:
# all_pkgs - an array of pkg's name
#
sub query_all_pkg {
    return split(/\n/, `rpm -qa`);
}

# parameters:
# pkg_name - string
#
# returns:
# pkg_exe_files - reference to array
#
sub query_pkg_exe_files {
    my $pkg_name = shift;

    my @rs = split(/\n/, `rpm -qlv $pkg_name`);

    my $ret = [];

    foreach my $line (@rs)
    {
        my @parts = $line =~ m/^([\S]+)[^\/]*(.*)$/;

        my @privileg = $parts[0] =~ 
            m/^-[r-][w-]([x-])[r-][w-]([x-])[r-][w-]([x-])$/;

        if ($#privileg == -1)
        {
            next;
        }
        else
        {
            if ($privileg[0] eq "x" or $privileg[1] eq "x" or 
                $privileg[2] eq "x")
            {
                if ($parts[1] =~ m/.*\.(sh|py|pyc|pl|guess|pyo)$/) 
                {
                    next;
                }
                push @$ret, ($parts[1]);
            }
        }
    }

    return $ret;
}

# parameters:
# file_path - target file path
#
# returns:
# dep_files - reference to array of file paths the target file
#             depends on.
sub query_dep_files {
    my $file_path = shift;
    my $ret = [];

    my @rs = split /\n/, `ldd $file_path`;

    foreach my $line (@rs)
    {
        my @result = $line =~ m/^.*=>[\s]*(\/[\S]+)[\s]*.*$/;

        if ($#result == -1)
        {
            @result = $line =~ m/^[\s]*(\/[\S]+)[\s]*.*$/;

            if ($#result == -1)
            {
                next;
            }
        }

        push @$ret, ($result[0]);
    }

    return $ret;
}

1;

