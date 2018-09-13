package ascii_draw;

use strict;
use warnings;

BEGIN {
    require Exporter;

    our $VERSION = 1.00;

    our @EXPORT = qw(draw_dep_graph);
}

# parameters:
# node - target node
# node_depth - reference to a hash, representing each node's
#              depth.
# depth_node - reference to array of array, representing each
#              depth's node set.
# dep - reference to hash of hash, representing the dependency
#       graph.
sub calc_node_depth {
    my $node = shift;
    my $node_depth = shift;
    my $depth_node = shift;
    my $dep = shift;
    
    print "calc node depth: $node\n";

    return if defined ${$node_depth}{$node};

    my $value = ${$dep}{$node};
    my $dep_nodes = ${$value}{"deps"};
    my $depth = 0;

    foreach my $dep_node (@$dep_nodes)
    {
        unless (defined ${$node_depth}{$dep_node})
        {
            calc_node_depth(
                $dep_node, $node_depth, $depth_node, $dep
            ); 
        }

        my $i = ${$node_depth}{$dep_node};
        if ($depth < ($i + 1))
        {
            $depth = $i + 1;
        }
    }

    ${$node_depth}{$node} = $depth;

    push @{${$depth_node}[$depth]},($node);
}

# parameters:
# dep - reference to hash of hash, representing the dependency
#       graph.
# node - to draw
# fd - file handle to store result
sub draw_node {
    my $dep = shift;
    my $node = shift;
    my $fd = shift;

    print $fd "$node(" . ${${$dep}{$node}}{"desc"} . ")\n";
}

# parameters:
# dep - reference to hash of hash, representing the dependency
#       graph.
# depth_node - reference to array of array, representing each
#              depth's node set.
# fd - file handle to store result
sub draw_depth_node {
    my $dep = shift;
    my $depth_node = shift;
    my $fd = shift;

    my $i = 0;
    foreach my $r (@$depth_node)
    {
        print $fd "level $i:\n";
        foreach my $node (@$r)
        {
            draw_node($dep, $node, $fd);
        }

        print $fd "\n";
        $i = $i + 1;
    }
}

# parameters:
# dep - reference to hash of hash, representing the dependency
#       graph.
# node_a - node 
# node_b - node
#
# is node_a depends on node_b
sub is_dep_on {
    my $dep = shift;
    my $node_a = shift;
    my $node_b = shift;

    for my $node (@{${${$dep}{$node_a}}{"deps"}})
    {
        return 1 if $node eq $node_b;
    }

    return 0;
}

# parameters:
# array_nodes - reference to array
# node - node
#
# returns:
# index - index of found node in array
sub is_node_exist {
    my $array_nodes = shift;
    my $node = shift;

    my $index = 0;

    foreach my $i (@$array_nodes)
    {
        return $index if $i eq $node; 

        $index = $index + 1;
    }

    return -1;
}

# parameters:
# dep - reference to hash of hash, representing the dependency
#       graph.
# node - root node
# postfix_nodes - reference to array
#
sub postfix_dep_nodes {
    my $dep = shift;
    my $node = shift;
    my $postfix_nodes = shift;
    
    my $dep_set = ${${$dep}{$node}}{"deps"};

    foreach my $dep_node (@$dep_set)
    {
        my @rs = is_node_exist($postfix_nodes, $dep_node);

        next if $rs[0] != -1;

        postfix_dep_nodes($dep, $dep_node, $postfix_nodes);
    }

    push @$postfix_nodes, ($node);
}

sub draw_blank_line {
    my $postfix_nodes = shift;
    my $dep_node = shift;
    my $fd = shift;

    foreach my $prev_node (@$postfix_nodes)
    {
        if ($prev_node eq $dep_node)
        {
            last;
        }
        else
        {
            print $fd "| ";
        }
    }

    print $fd "\n";
}

# parameters:
# dep - reference to hash of hash, representing the dependency
#       graph.
# node - node
# fd - file handle to store result
sub draw_node_tree {
    my $dep = shift;
    my $node = shift;
    my $fd = shift;

    my $postfix_nodes = [];
    my $first = 1;

    print $fd "dependency for $node:\n";

    postfix_dep_nodes($dep, $node, $postfix_nodes);

    foreach my $dep_node (@$postfix_nodes)
    {
        if ($first)
        {
            $first = 0;
        }
        else
        {
            draw_blank_line($postfix_nodes, $dep_node, $fd);
        }

        foreach my $prev_node (@$postfix_nodes)
        {
            if ($prev_node eq $dep_node)
            {
                last;
            }
            elsif (is_dep_on($dep, $dep_node, $prev_node))
            {
                print $fd "*-";
            }
            else
            {
                print $fd "|-";
            }
        }

        draw_node($dep, $dep_node, $fd);
    }

    print $fd "\n";
}

# parameters:
# dep - reference to hash of hash, representing the dependency
#       graph.
# depth_node - reference to array of array, representing each
#       depth's node set.
# fd - file handle to store result
# 
sub draw_dep_tree {
    my $dep = shift;
	my $depth_node = shift;
	my $fd = shift;

    foreach my $r (@$depth_node)
    {
        foreach my $node (@$r)
        {
            draw_node_tree($dep, $node, $fd);
        }
    }
}

# parameters:
# node - current process node
# dep - reference to hash of hash, representing the dependency
#       graph.
# node_visited - reference to hash, representing nodes been
#                visited.
# cycles - reference to array of array
# visited_stack - reference to array, representing current 
#                 visiting stack.
sub recognize_cycles {
    my $node = shift;
    my $dep = shift;
    my $node_visited = shift;
    my $cycles = shift;
    my $visited_stack = shift;

    print "recognize cycles, visiting node:$node\n";
    print "visited_stack is:\n";
    print @$visited_stack;
    print "\n";

    return if defined ${$node_visited}{$node};

    my $value = ${$dep}{$node};
    my $dep_nodes = ${$value}{"deps"};

    foreach my $dep_node (@$dep_nodes)
    {
        if (defined ${$node_visited}{$dep_node})
        {
            next;
        }
        else
        {
            my @rs = is_node_exist($visited_stack, $dep_node);
            if ($rs[0] == -1)
            {
                push @$visited_stack, ($dep_node);
                recognize_cycles($dep_node, $dep,
                    $node_visited, $cycles, $visited_stack);
                pop @$visited_stack;
            }
            else
            {
                my $cycle = [];
                push @$cycle, 
                    @{$visited_stack}[$rs[0]..$#{$visited_stack}];
                
                push @$cycles, ($cycle);
            }
        }
    }

    ${$node_visited}{$node} = 1;
}

# parameters:
# new_dep - reference to hash of hash, representing the dependency
#       graph with cycles picked out.
# node_a - node
# node_b - node
sub erase_dep {
    my $new_dep = shift;
    my $node_a = shift;
    my $node_b = shift;

    my $value = ${$new_dep}{$node_a};
    return unless defined $value;

    my @rs = is_node_exist(${$value}{"deps"}, $node_b);
    return if $rs[0] == -1;

    my $deps = [];
    my $pos1 = $rs[0]-1;
    my $pos2 = $rs[0]+1;
    my $n = $#{${$value}{"deps"}};
    push @$deps, @{${$value}{"deps"}}[0..$pos1];
    push @$deps, @{${$value}{"deps"}}[$pos2..$n];

    ${${$new_dep}{$node_a}}{"deps"} = $deps;
}

# parameters:
# dep - reference to hash of hash, representing the dependency
#       graph.
# new_dep - reference to hash of hash, representing the dependency
#       graph with cycles picked out.
# cycles - reference to array of array
sub pick_out_cycles {
    my $dep = shift;
    my $new_dep = shift;
    my $cycles = shift;

    print "picking out cycles\n";

    my $node_visited = {};
    my $visited_stack = [];

    foreach my $node (keys %{$dep})
    {
        push @$visited_stack, ($node);
        recognize_cycles($node, $dep, $node_visited, $cycles,
            $visited_stack);
        pop @$visited_stack;
    }

    foreach my $node (keys %$dep)
    {
        my $value = ${$dep}{$node};
        ${$new_dep}{$node} = {
            "deps" => [],
            "desc" => ${$value}{"desc"},
        };
        push @{${${$new_dep}{$node}}{"deps"}}, 
            @{${$value}{"deps"}};
    }

    foreach my $cycle (@$cycles)
    {
        # act as a sentinal
        push @$cycle, ${$cycle}[0];

        my $n = $#{$cycle};
        my $i = 0;
        while ($i < $n)
        {
            erase_dep($new_dep, ${$cycle}[$i], ${$cycle}[$i+1]);
            $i = $i + 1;
        }

        pop @$cycle;
    }
}

# parameters:
# cycles - reference to array of array
# fd - file handle to store result
sub draw_cycles {
    my $cycles = shift;
    my $fd = shift;

    my $n = $#{$cycles} + 1;
    my $i = 1;
    print $fd "total $n cycles:\n";

    foreach my $cycle (@$cycles)
    {
        print $fd "cycle $i\n";
        foreach my $node (@$cycle)
        {
            print $fd "$node\n";
        }

        $i = $i + 1;
    }

    print $fd "\n";
}

# parameters:
# dep - reference to hash of hash, representing the dependency
#       graph.
# result_file - file path to store result
#
sub draw_dep_graph {
    my $dep = shift;
    my $result_file = shift;

    open my $fd, ">", $result_file or 
        die "cannot open file:$result_file, $!";

    my $new_dep = {};
    my $cycles = [];

    pick_out_cycles($dep, $new_dep, $cycles);

    draw_cycles($cycles, $fd);

    my $node_depth = {};
    my $depth_node = [];
    calc_node_depth($_, $node_depth, $depth_node, $new_dep) 
        foreach keys %$dep;

    draw_depth_node($new_dep, $depth_node, $fd);
	draw_dep_tree($new_dep, $depth_node, $fd);

    close $fd or 
        die "cannot close file:$result_file, $!";
}

1;

