use strict;
use warnings;

require '../lib/ascii_draw.pm';

sub test_calc_node_depth {
    my $node = "ccc";
    my $node_depth = {};
    my $depth_node = [];
    my $dep = {
        "aaa" => {
            "deps" => ["bbb"],
            "desc" => "item aaa",
        },
        "bbb" => {
            "deps" => [],
            "desc" => "item bbb",
        },
        "ccc" => {
            "deps" => ["aaa"],
            "desc" => "item ccc",
        },
    };

    ascii_draw::calc_node_depth(
        $node, $node_depth, $depth_node, $dep
    );

    foreach my $i (keys %$node_depth)
    {
        print "node:$i, depth:${$node_depth}{$i}\n";
    }

    my $depth = 0;
    foreach my $set (@$depth_node)
    {
        print "depth $depth set:\n";
        foreach my $i (@$set)
        {
            print "$i\n";
        }

        $depth = $depth + 1;
    }
}

sub test_draw_node {
    my $dep = {
        "aaa" => {
            "deps" => ["bbb"],
            "desc" => "item aaa",
        },
        "bbb" => {
            "deps" => [],
            "desc" => "item bbb",
        },
        "ccc" => {
            "deps" => ["aaa"],
            "desc" => "item ccc",
        },
    };
    my $node = "ccc";
    my $fd;

    open($fd, ">", "../data/result.txt") or 
        die "failed to open result.txt, err:$!\n";

    ascii_draw::draw_node($dep, $node, $fd);

    close $fd;
}

sub test_draw_depth_node {
    my $dep = {
        "aaa" => {
            "deps" => ["bbb"],
            "desc" => "item aaa",
        },
        "bbb" => {
            "deps" => [],
            "desc" => "item bbb",
        },
        "ccc" => {
            "deps" => ["aaa"],
            "desc" => "item ccc",
        },
    };
    my $depth_node = [];
    my $fd;
    my $node = "ccc";
    my $node_depth = {};

    ascii_draw::calc_node_depth($node, $node_depth,
        $depth_node, $dep);

    open($fd, ">", "../data/result.txt") or
        die "failed to open result.txt, err:$!\n";

    ascii_draw::draw_depth_node($dep, $depth_node, $fd);

    close $fd;
}

sub test_is_dep_on {
    my $dep = {
        "aaa" => {
            "deps" => ["bbb"],
            "desc" => "item aaa",
        },
        "bbb" => {
            "deps" => [],
            "desc" => "item bbb",
        },
        "ccc" => {
            "deps" => ["aaa"],
            "desc" => "item ccc",
        },
    };
    my $node_a = "aaa";
    my $node_b = "bbb";
    my @rs = ascii_draw::is_dep_on($dep, $node_a, $node_b);

    print "$_\n" foreach @rs;
}

sub test_is_node_exist {
    my $array_nodes = ["aaa", "bbb", "ccc"];
    my $node = "aaa";

    my @rs = ascii_draw::is_node_exist($array_nodes, $node);
    print "$_\n" foreach @rs;

    $node = "bbb";
    @rs = ascii_draw::is_node_exist($array_nodes, $node);
    print "$_\n" foreach @rs;

    $node = "ccc";
    @rs = ascii_draw::is_node_exist($array_nodes, $node);
    print "$_\n" foreach @rs;

    $node = "xxx";
    @rs = ascii_draw::is_node_exist($array_nodes, $node);
    print "$_\n" foreach @rs;
}

sub test_postfix_dep_nodes {
    my $dep = {
        "aaa" => {
            "deps" => ["bbb"],
            "desc" => "item aaa",
        },
        "bbb" => {
            "deps" => [],
            "desc" => "item bbb",
        },
        "ccc" => {
            "deps" => ["aaa"],
            "desc" => "item ccc",
        },
    };
    my $node = "ccc";
    my $postfix_nodes = [];

    ascii_draw::postfix_dep_nodes($dep, $node, $postfix_nodes);

    print "$_\n" foreach @$postfix_nodes;
}

sub test_draw_blank_line {
    my $postfix_nodes = ["bbb", "aaa", "ccc"];
    my $dep_node = "ccc";
    my $fd;

    open $fd, ">", "../data/result.txt" or
        die "failed to open result.txt, err:$!\n";

    ascii_draw::draw_blank_line($postfix_nodes, $dep_node, $fd);

    close $fd;
}

sub test_draw_node_tree {
    my $dep = {
        "aaa" => {
            "deps" => ["bbb"],
            "desc" => "item aaa",
        },
        "bbb" => {
            "deps" => [],
            "desc" => "item bbb",
        },
        "ccc" => {
            "deps" => ["aaa"],
            "desc" => "item ccc",
        },
    };
    my $node = "ccc";
    my $fd;

    open $fd, ">", "../data/result.txt" or
        die "failed to open result.txt, err:$!\n";

    ascii_draw::draw_node_tree($dep, $node, $fd);

    close $fd;
}

sub test_draw_dep_tree {
    my $dep = {
        "aaa" => {
            "deps" => ["bbb"],
            "desc" => "item aaa",
        },
        "bbb" => {
            "deps" => [],
            "desc" => "item bbb",
        },
        "ccc" => {
            "deps" => ["aaa"],
            "desc" => "item ccc",
        },
    };
    my $depth_node = [["bbb"],["aaa"],["ccc"]];
    my $fd;

    open $fd, ">", "../data/result.txt" or
        die "failed to open result.txt, err:$!\n";

    ascii_draw::draw_dep_tree($dep, $depth_node, $fd);

    close $fd;
}

sub test_recognize_cycles {
    my $dep = {
        "aaa" => {
            "deps" => ["bbb"],
            "desc" => "item aaa",
        },
        "bbb" => {
            "deps" => ["aaa"],
            "desc" => "item bbb",
        },
        "ccc" => {
            "deps" => ["aaa"],
            "desc" => "item ccc",
        },
    };
    my $node = "ccc";
    my $node_visited = {};
    my $cycles = [];
    my $visited_stack = ["ccc"];

    ascii_draw::recognize_cycles($node,
        $dep, $node_visited, $cycles, $visited_stack);

    foreach my $i (keys %$node_visited)
    {
        print "visited node:$i\n";
    }

    foreach my $cycle (@$cycles)
    {
        print "cycle:\n";
        foreach my $i (@$cycle)
        {
            print "$i\n";
        }
    }

    print "visited stack:\n";
    foreach my $i (@$visited_stack)
    {
        print "$i\n";
    }
}

sub test_erase_dep {
    my $new_dep = {
        "aaa" => {
            "deps" => ["bbb"],
            "desc" => "item aaa",
        },
        "bbb" => {
            "deps" => ["aaa"],
            "desc" => "item bbb",
        },
        "ccc" => {
            "deps" => ["aaa"],
            "desc" => "item ccc",
        },
    };
    my $node_a = "aaa";
    my $node_b = "bbb";

    ascii_draw::erase_dep($new_dep, $node_a, $node_b);

    foreach my $i (keys %$new_dep)
    {
        print "node $i deps on:\n";
        foreach my $j (@{${${$new_dep}{$i}}{"deps"}})
        {
            print "$j\n";
        }
    }
}

sub test_pick_out_cycles {
    my $new_dep = {};
    my $cycles = [];
    my $dep = {
        "aaa" => {
            "deps" => ["bbb"],
            "desc" => "item aaa",
        },
        "bbb" => {
            "deps" => ["aaa"],
            "desc" => "item bbb",
        },
        "ccc" => {
            "deps" => ["aaa"],
            "desc" => "item ccc",
        },
    };

    ascii_draw::pick_out_cycles($dep, $new_dep, $cycles);

    foreach my $node (keys %$new_dep)
    {
        print "node:$node\n";
        print "deps:\n";
        my $value = ${$new_dep}{$node};
        print @{${$value}{"deps"}};
        print "\n";
    }

    my $i = 1;
    foreach my $cycle (@$cycles)
    {
        print "cycle $i:\n";
        foreach my $node (@$cycle)
        {
            print "$node\n";
        }
        $i = $i + 1;
    }
}

sub test_draw_cycles {
    my $cycles = [["aaa", "bbb"]];
    my $fd;

    open $fd, ">", "../data/result.txt" or
        die "failed to open result.txt, err:$!\n";

    ascii_draw::draw_cycles($cycles, $fd);

    close $fd;
}

sub test_draw_dep_graph {
    my $dep = {
        "aaa" => {
            "deps" => ["bbb"],
            "desc" => "item aaa",
        },
        "bbb" => {
            "deps" => ["aaa"],
            "desc" => "item bbb",
        },
        "ccc" => {
            "deps" => ["aaa"],
            "desc" => "item ccc",
        },
    };
    my $result_file = "../data/result.txt";

    ascii_draw::draw_dep_graph($dep, $result_file);
}

#test_calc_node_depth();
#test_draw_node();
#test_draw_depth_node();
#test_is_dep_on();
#test_is_node_exist();
#test_postfix_dep_nodes();
#test_draw_blank_line();
#test_draw_node_tree();
#test_draw_dep_tree();
#test_recognize_cycles();
#test_erase_dep();
#test_draw_cycles();
test_draw_dep_graph();

