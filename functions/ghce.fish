function ghce
    set FUNCNAME (status function)

    set __USAGE "Wrapper around `gh copilot explain` to explain a given input command in natural language.

USAGE
  $FUNCNAME [flags] <command>

FLAGS
  -d, --debug   Enable debugging
  -h, --help    Display help usage

EXAMPLES

# View disk usage, sorted by size
$FUNCNAME 'du -sh | sort -h'

# View git repository history as text graphical representation
$FUNCNAME 'git log --oneline --graph --decorate --all'

# Remove binary objects larger than 50 megabytes from git history
$FUNCNAME 'bfg --strip-blobs-bigger-than 50M'
"

    set GH_DEBUG "$GH_DEBUG"
    set -l OPTIND 1

    for arg in $argv
        switch $arg
            case -h --help
                echo "$__USAGE"
                return 0
            case -d --debug
                set GH_DEBUG api
                set -e argv[$OPTIND] # Remove processed option
            case '--*'
                set opt (string replace -r -- '^--' '' $arg)
                switch $opt
                    case help
                        echo "$__USAGE"
                        return 0
                    case debug
                        set GH_DEBUG api
                        set -e argv[$OPTIND] # Remove processed option
                    case '*'
                        echo "Unknown option --$opt" >&2
                        return 1
                end
            case '-*'
                set option (string sub --start=2 $arg)
                for i in (string split '' -- $option)
                    switch $i
                        case h
                            echo "$__USAGE"
                            return 0
                        case d
                            set GH_DEBUG api
                            set -e argv[$OPTIND] # Remove processed option
                        case '*'
                            echo "Unknown option -$i" >&2
                            return 1
                    end
                end
                set OPTIND (math $OPTIND + 1)
        end

        # Update OPTIND for the non-option arguments
        while [ $OPTIND -gt 1 ]
            set -e argv[1]
            set OPTIND (math $OPTIND - 1)
        end

        env GH_DEBUG="$GH_DEBUG" gh copilot explain $argv
    end
end
