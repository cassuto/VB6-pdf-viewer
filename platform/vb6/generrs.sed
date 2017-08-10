
# Match the text inside the markers.
/gen{{/,/}}gen/{

# if (#define) goto defines
/^[[:space:]]*#[[:space:]]*define/b defines

# if (/**) goto description
/\/\*\*/b description

}

# Delete the unused data
d
b end


##
# Convert the defines
:defines
s/^[[:space:]]*#[[:space:]]*define[[:space:]]*\([[:alnum:]_]*\)[[:space:]]*\(.*\)[[:space:]]*$/    "\1",\n     \1 }, /
b end

##
# Convert descriptive comments. /** desc */
:description
# a burst. how to do N until end of comment?
/\*\//!N
/\*\//!N
/\*\//!N
/\*\//!N
/\*\//!N
/\*\//!N
/\*\//!N
/\*\//!N
/\*\//!N
/\*\//!N
/\*\//!N
/\*\//!N
/\*\//!N
/\*\//!N
/\*\//!N
/\*\//!N
/\*\//!N
/\*\//!N
/\*\//!N
/\*\//!N
/\*\//!N
/\*\//!N
/\*\//!N
/\*\//!N
/\*\//!N
/\*\//!N
/\*\//!N
/\*\//!N
/\*\//!N
# anything with @{ and @} is skipped
/@[\{\}]/d

# Fix double spaces
s/[[:space:]][[:space:]]/ /g

# Fix \# sequences (doxygen needs them, we don't).
s/\\#/#/g

# insert punctuation.
s/\([^.[:space:]]\)[[:space:]]*\*\//\1. \*\//

# convert /** short. more
s/[[:space:]]*\/\*\*[[:space:]]*/  { NULL, \"/
s/  { NULL, \"\([^.!?"]*[.!?][.!?]*\)/  { \"\1\",\n    \"\1/

# terminate the string
s/[[:space:]]*\*\//\"\,/

# translate empty lines into new-lines (only one, please).
s/[[:space:]]*[[:space:]]\*[[:space:]][[:space:]]*\*[[:space:]][[:space:]]*/\\n/g

# remove asterics.
s/[[:space:]]*[[:space:]]\*[[:space:]][[:space:]]*/ /g
b end


# next expression
:end
