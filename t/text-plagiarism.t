#!/usr/bin/env perl
use common::sense;
use Test::More qw(no_plan);
use Test::Differences;
use Readonly;
use Getopt::Long;
use Data::Dumper;
use File::Slurp qw(read_file);

Readonly our $METER_CORPUS_DIR          => 't/meter-corpus';

BEGIN {
    use_ok( 'Text::Plagiarism', qw(
        plagiarism_prepare
        plagiarism_prepare_text
        plagiarism_measure
    ) )
        or die "Bail out, main module can't be used!";
}

my %opts = (
);
GetOptions(
    'help'      => \$opts{help},
) or help("error while parsing options");

help()      if $opts{help};

my ($r);

$r   = Text::Plagiarism::string2shingles(
    string  => "fox",
    n       => 2,
);
eq_or_diff(
    $r,
    [],
    "string2shingles result for 1 word",
);

$r   = Text::Plagiarism::string2shingles(
    string  => "fox jumps",
    n       => 2,
);
eq_or_diff(
    $r,
    [
        'fox jumps',
    ],
    "string2shingles result for 2 words",
);

$r   = Text::Plagiarism::string2shingles(
    string  => "fox jumps very high",
    n       => 2,
);
eq_or_diff(
    $r,
    [
        'fox jumps',
        'jumps very',
        'very high',
    ],
    "string2shingles result for 4 words",
);

$r   = Text::Plagiarism::string2shingles(
    string  => "fox jumps very high. rabbit is also a good jumper.",
    n       => 2,
);
eq_or_diff(
    $r,
    [
        'fox jumps',
        'jumps very',
        'very high',
        'high rabbit',
        'rabbit is',
        'is also',
        'also a',
        'a good',
        'good jumper',
    ],
    "string2shingles result for 4 words",
);

$r   = Text::Plagiarism::string2sentences(
    string  => "fox jumps very high",
);
eq_or_diff(
    $r,
    [
        'fox jumps very high',
    ],
    "string2sentences result for 1 sentence without dot",
);

$r   = Text::Plagiarism::string2sentences(
    string  => "fox jumps very high.",
);
eq_or_diff(
    $r,
    [
        'fox jumps very high',
    ],
    "string2sentences result for 1 sentence with dot",
);

$r   = Text::Plagiarism::string2sentences(
    string  => "fox jumps very high. so high that it can reach the sky",
);
eq_or_diff(
    $r,
    [
        'fox jumps very high',
        'so high that it can reach the sky',
    ],
    "string2sentences result for 2 sentences with 1 dot",
);

$r   = Text::Plagiarism::string2sentences(
    string  => "fox jumps very high. so high that it can reach the sky. ",
);
eq_or_diff(
    $r,
    [
        'fox jumps very high',
        'so high that it can reach the sky',
    ],
    "string2sentences result for 2 sentences with 2 dots",
);

$r   = Text::Plagiarism::prepare_set4jaccard_coefficient(
    set  => [
        'fox jumps',
        'jumps very',
        'very high',
    ],
);
eq_or_diff(
    $r,
    {
        'fox jumps'     => 1,
        'jumps very'    => 1,
        'very high'     => 1,
    },
    "prepare_se4jaccard_coefficient no repeatitions",
);

$r   = Text::Plagiarism::prepare_set4jaccard_coefficient(
    set  => [
        'fox jumps',
        'jumps very',
        'very high',
        'high fox',
        'fox jumps',
    ],
);
eq_or_diff(
    $r,
    {
        'fox jumps'     => 2,
        'jumps very'    => 1,
        'very high'     => 1,
        'high fox'      => 1,
    },
    "prepare_se4jaccard_coefficient no repeatitions",
);

$r   = Text::Plagiarism::jaccard_coefficient(
    set0 => [
        'fox jumps',
        'jumps very',
        'very high',
    ],
    set1 => [
        'rabbit jumps',
        'jumps too',
        'too low',
    ],
);
is($r, 0, "jaccard_coefficient");

$r   = Text::Plagiarism::jaccard_coefficient(
    set0 => [
        'fox jumps',
        'jumps very',
        'very high',
    ],
    set1 => [
        'rabbit jumps',
        'jumps very',
        'very high',
    ],
);
is($r, 2/4, "jaccard_coefficient");

$r   = Text::Plagiarism::jaccard_coefficient2(
    set0 => [
        'fox jumps',
        'jumps very',
        'very high',
    ],
    set1 => [
        'rabbit jumps',
        'jumps too',
        'too low',
    ],
);
is($r, 0, "jaccard_coefficient2 no intersection");

$r   = Text::Plagiarism::jaccard_coefficient2(
    set0 => [
        'fox jumps',
        'jumps very',
        'very high',
    ],
    set1 => [
        'rabbit jumps',
        'jumps very',
        'very high',
    ],
);
cmp_ok(abs($r - 2/3), '<=', .01, "jaccard_coefficient2 has intersection");

# wholly derived
$r   = plagiarism_measure(
    query_text      => scalar read_file("$METER_CORPUS_DIR/newspapers/rawtexts/showbiz/08.08.99/edmonds/edmonds13_times.txt"),
    document_text   => scalar read_file("$METER_CORPUS_DIR/PA/rawtexts/showbiz/08.08.99/edmonds/edmonds1.txt"),
    result_sentence_measure_function    => 'result_sentence_measure_avg',
);
cmp_ok(abs($r-0.838131313131313), '<=', .01, "plagiarism measure wholly derived, avg");

$r   = plagiarism_measure(
    query_text      => scalar read_file("$METER_CORPUS_DIR/newspapers/rawtexts/showbiz/08.08.99/edmonds/edmonds13_times.txt"),
    document_text   => scalar read_file("$METER_CORPUS_DIR/PA/rawtexts/showbiz/08.08.99/edmonds/edmonds1.txt"),
    result_sentence_measure_function    => 'result_sentence_measure_weighted',
);
cmp_ok(abs($r-0.855192955192955), '<=', .01, "plagiarism measure wholly derived, weighted");

$r   = plagiarism_measure(
    query_text      => scalar read_file("$METER_CORPUS_DIR/newspapers/rawtexts/showbiz/08.08.99/edmonds/edmonds13_times.txt"),
    document_text   => scalar read_file("$METER_CORPUS_DIR/PA/rawtexts/showbiz/08.08.99/edmonds/edmonds1.txt"),
    result_sentence_measure_function    => sub {
        my %a   = (
            sentences   => [],
            ngram       => $Text::Plagiarism::DEFAULT_NGRAM,
            @_
        );
        my $n_sentences = scalar @{ $a{sentences} };
        return 0    unless $n_sentences;

        my $n_derived_sentences = 0;
        foreach(@{ $a{sentences} }) {
            $n_derived_sentences++
                if .5 <= $_->{plagiarism_measure};
        }

        $n_derived_sentences / $n_sentences;
    },
);
cmp_ok(abs($r-1), '<=', .01, "plagiarism measure wholly derived, weighted");

# partially derived
$r   = plagiarism_measure(
    query_text      => scalar read_file("$METER_CORPUS_DIR/newspapers/rawtexts/showbiz/08.08.99/edmonds/edmonds16_guardian.txt"),
    document_text   => scalar read_file("$METER_CORPUS_DIR/PA/rawtexts/showbiz/08.08.99/edmonds/edmonds1.txt"),
);
cmp_ok(abs($r-0.348468991636006), '<=', .01, "plagiarism measure partially derived");

# non derived
$r   = plagiarism_measure(
    query_text      => scalar read_file("$METER_CORPUS_DIR/newspapers/rawtexts/showbiz/08.08.99/edmonds/edmonds11_express.txt"),
    document_text   => scalar read_file("$METER_CORPUS_DIR/PA/rawtexts/showbiz/08.08.99/edmonds/edmonds1.txt"),
);
cmp_ok(abs($r-0.179874206268991), '<=', .01, "plagiarism measure non derived");

exit;

sub help {
    say join("\n", @_)."\n";
    say <<HELP;
Usage:
$0 [-h|--help] [--type raw|annotated]

Options:
-h|--help               - print this help message
--type raw|annotated    - which type of articles to use

Description:
Provide tests using meter-corpus

HELP
    exit scalar @_;
}
