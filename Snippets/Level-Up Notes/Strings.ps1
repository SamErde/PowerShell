# Strings can be wrapped in single quotes or double quotes
$String1 = 'This is a string.'
$String1

$String2 = 'This is a string.'
$String2

# What are the benefits of using single quotes or double quotes?
# Single quotes are "faster" and "safer" because they don't expand variables or escape characters. Two single quotes can be used to escape a single quote, but can also be confusing when they appear together.

$NumberOfDays = 7
$String3 = 'There are $NumberOfDays days in a week.'
$String3

$String4 = "There are $NumberOfDays days in a week."
$String4

# What if you want to put a colon in front of a variable in a string?
$String5 = "There are: $NumberOfDays days in a week."
$String5

# But this fails because colons are used to define the scope of a variable or function.
# $String6 = "$NumberOfDays: how many days are in a week?"
# $String6
$String6 = "${NumberOfDays}: how many days are in a week?"
$String6


# Here-Strings are used to create multi-line strings.
$Palindrome1 = @'
a man
a plan
a canal
panama
'@
$Palindrome1

$Palindrome2 = @'
'A man, a plan, a canal - Panama' is a famous palindrome.
A palindrome is a word, number, phrase, or other sequence of symbols that reads the same backwards as forwards.
The sentence "A man, a plan, a canal - Panama" reads the same backwards as forwards.
'@
$Palindrome2
# Note the mixed use of single and double quotes in the above example.

# Without using a here-string, we would have to use the escape character to insert newlines. (Double quotes required!)
$Palindrome3 = "a man`na plan`na canal`npanama"
$Palindrome3

# As seen above, the escape character (a backtick) can be used to insert special characters.
$String6 = "This is a string with a backtick ` and a newline `n and a tab `t."
$String6

$Palindrome5 = "'A man, a plan, a canal - Panama' is a famous palindrome. `nA palindrome is a word, number, phrase, or other sequence of symbols that reads the same backwards as forwards. `nThe sentence 'A man, a plan, a canal - Panama'
reads the same backwards as forwards."
$Palindrome5


$InAMonth = 30
$NumberOfDays = 7
# The -f operator can be used to format strings. The format string is on the left, and the values to be inserted are on the right.
$String7 = 'There are {0} days in a week and {1} days in a month. Somtimes.' -f $NumberOfDays, $InAMonth
$String7

# Let's combine that with a here-string to create a template:
$YourName = 'Sam Erde'
$PhoneNumber = '867-5389'
$HerName = 'Jenny'
$Template = @'
Hello, {0},
To obtain your free PowerShell stickers, please call {1} at {2}.
'@ -f $YourName, $HerName, $PhoneNumber

$Template
