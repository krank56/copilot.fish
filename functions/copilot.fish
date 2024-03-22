function ghcs
    set FUNCNAME (status function)
    set TARGET shell
    set GH_DEBUG $GH_DEBUG

    set __USAGE "\
Wrapper around \`gh copilot suggest\` to suggest a command based on a natural language description of the desired output effort.
Supports executing suggested commands if applicable.

USAGE
  $FUNCNAME [flags] <prompt>

FLAGS
  -d, --debug              Enable debugging
  -h, --help               Display help usage
  -t, --target target      Target for suggestion; must be shell, gh, git
                           default: $TARGET

EXAMPLES

- Guided experience
  $FUNCNAME

- Git use cases
  $FUNCNAME -t git 'Undo the most recent local commits'
  $FUNCNAME -t git 'Clean up local branches'
  $FUNCNAME -t git 'Setup LFS for images'

- Working with the GitHub CLI in the terminal
  $FUNCNAME -t gh 'Create pull request'
  $FUNCNAME -t gh 'List pull requests waiting for my review'
  $FUNCNAME -t gh 'Summarize work I have done in issues and pull requests for promotion'

- General use cases
  $FUNCNAME 'Kill processes holding onto deleted files'
  $FUNCNAME 'Test whether there are SSL/TLS issues with github.com'
  $FUNCNAME 'Convert SVG to PNG and resize'
  $FUNCNAME 'Convert MOV to animated PNG'"

    for arg in $argv
        switch $arg
            case -d --debug
                set GH_DEBUG api
                set -e argv[1]
            case -h --help
                echo "$__USAGE"
                return 0
            case -t --target
                set TARGET $argv[2]
                set -e argv[1..2]
            case '-*'
                echo "Unrecognized option '$arg'"
                return 1
        end
    end

    set TMPFILE (mktemp -t gh-copilotXXX)
    function cleanup --on-event fish_exit
        rm -f $TMPFILE
    end

    if env GH_DEBUG=$GH_DEBUG gh copilot suggest -t $TARGET $argv --shell-out $TMPFILE
        if test -s $TMPFILE
            set FIXED_CMD (cat $TMPFILE)
            history add "$FIXED_CMD"
            eval $FIXED_CMD
        end
    else
        return 1
    end
end



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
