# This is an array
$Food = @( 'Apples', 'Bananas', 'Cherries', 'Durian', 'Eggplant' )

$Food.Count

# This is a string
$Food = 'Apples,Bananas,Cherries,Durian,Eggplant'

$Food
$Food.Count

# Let's slice this up
$Food.Split(',')

# The split method has 3 overloads: the separator, the number of items to return, and the options.
# The default is to return all items, so we can just use the separator.
$Food.Split(',', 1)

$Food.Split(',', 2)

$Food.Split(',', 3)

# The split method returns an array of strings, and we can reference the individual elements using the index.
( $Food.Split(',') ).Count
$Food.Split(',')[0]
$Food.Split(',')[2]
$Food.Split(',')[-1] # Get the last item. Negative index counts from the end of the array.
$Food.Split(',')[-2] # Get the 2nd to last item.

# Note that the separator is removed from the split strings:
$Food.Split('p')
# The split method is case-sensitive.
$Food.Split('P')
# We can use the ToLower() method to convert the string to lowercase before splitting OR we can use the -Split operator.

# The -split operator, which is a case-insensitive version of the split method.
$Food -split 'p'
$Food -split 'P'
