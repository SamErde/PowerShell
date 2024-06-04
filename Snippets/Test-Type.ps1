function Test-Type {
    param(
        [Parameter(Mandatory)]
        $Object
    )

    switch ( ($Object.GetType().Name) ) {
        String { 'String' }
        Int32 { 'Int32' }
        Int64 { 'Int64' }
        Double { 'Double' }
        Boolean { 'Bool' }
    }
}
