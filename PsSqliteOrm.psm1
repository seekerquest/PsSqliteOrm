<#
.SYNOPSIS
    Start a new connection to a SQLite database.
.DESCRIPTION
    Starts a new connection to a SQLite database by specifying the file path.
.EXAMPLE
    PS C:\> New-Connection -Path "C:\temp\sqlite\sqlite.db"
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>

function New-Connection {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )
    try {
        if (Test-Path $Path) {
            $DbConnection = New-Object -TypeName System.Data.sqlite.sqliteConnection

            $DbConnection.ConnectionString = "data source=$Path"
        }
    }
    catch {
        Write-Warning -Message "Unable to open databse connection to $Path. Please check if path is correct!"
    }

    return $DbConnection
}

<#
.SYNOPSIS
    Add new table to an existing SQLite datbase
.DESCRIPTION
    Add a new table to an exisiting database. Need to specify the database connection using New-Connection cmdlet.
.EXAMPLE
    PS C:\> $Connection = New-Connection -Path "c:\temp\sqlite\sqlite.db"
    PS C:\> New-Table -DbConnection $Connection -Tablename Sales
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
function New-Table {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Data.SQLite.SQLiteConnection]
        $DbConnection,
        # Table Name
        [Parameter(Mandatory = $true)]
        [string]
        $TableName,
        # Parameter help description
        [Parameter(Mandatory = $true)]
        [hashtable]
        $Column,
        [Parameter()]
        [Bool]
        $Close
        
    )
    BEGIN {
        $Params = ""
        foreach ($item in $Column.Keys) {
            $Params += "$item $($Column[$item]),"
        }
        $Query = "CREATE TABLE $TableName ($Params);"
        $Query = $Query.Replace(",)", ")")
        $DbConnection.Open()
    }
    PROCESS {
        $SqlCommand = $DbConnection.CreateCommand()
        $SqlCommand.CommandText = $Query
        $SqlCommand.ExecuteNonQuery()
        return $SqlCommand
    }
    END {
        if ($Close) {
            $DbConnection.Close()
        }
        
    }
}
<#
.SYNOPSIS
    Close a SQLite database connection.
.DESCRIPTION
    Close a SQLite database connection.
.EXAMPLE
    PS C:\> Close-Connection -DbConnection $Connection
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    This cmdlet doesn't dispose of the database connection, it only closes it. If you need to dispose of the connection, use the
    "-Dipose $true" paramater.
#>
function Close-Connection {
    [CmdletBinding()]
    param (
        [Parameter()]
        [System.Data.SQLite.SQLiteConnection]
        $DbConnection
    )
    
    try {
        if ($DbConnection.State -eq "Closed") {
            Write-Warning -Message "There is nothing to close. It looks like the specified databse connection is already close."
        }
        else {
            $DbConnection.Close()
            $DbConnection.Dispose()
            Write-host "Connection Closed"
        }
    }
    catch {
        Write-Error -Message $_
    }
}
<#
.SYNOPSIS
    Add rows of data to a SQLite database table.
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> Add-Data -DbConnection $Connection -TableName Sales -Column @{key1="";key2=""}
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
function Add-Data {
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter(Mandatory = $true)]
        [System.Data.SQLite.SQLiteConnection]
        $DbConnection,
        [Parameter(Mandatory = $true)]
        [string]
        $TableName,
        # Data values to add to the table
        [Parameter(Mandatory = $true)]
        [hashtable]
        $Value,
        [Parameter()]
        [Bool]
        $Close
    )
    
    BEGIN {
        $KeyExtract = ""
        $ValueExtract = ""
        foreach ($item in $Value.Keys) {
            $KeyExtract += "$item,"
            if ($Value[$item].GetType().Name -eq "String" ) {
                $ValueExtract += "'$($Value[$item])',"
            }
            else {
                $ValueExtract += "$($Value[$item]),"
            }
            
        }
        $Query = "INSERT INTO $TableName($KeyExtract) VALUES($ValueExtract)"
        $Query = $Query.Replace(",)", ")")
        if ($DbConnection.State -eq 'Closed') {
            $DbConnection.Open()
        }
    }
    PROCESS {
        $Command = $DbConnection.CreateCommand()
        $Command.CommandText = $Query
        $Command.ExecuteNonQuery()
        return $Command
    }
    END {
        if ($Close) {
            $DbConnection.Close()
        }
        
    }
}
<#
.SYNOPSIS
    Query data from a SQLite database table. 
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
function Get-Data {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Data.SQLite.SQLiteConnection]
        $DbConnection,
        # Specify table name
        [Parameter()]
        [string]
        $TableName,
        # Parameter help description
        [Parameter()]
        [hashtable]
        $Data,
        # Specify if you want connection to stay open
        [Parameter()]
        [Bool]
        $Close,
        # Get all data
        [Parameter()]
        [bool]
        $All
    )
    BEGIN {
        if ($All) {
            $Query = "SELECT * FROM $TableName"
        }
        else {
            $Values = ""
            foreach ($key in $Data.Keys) {
                if ($Data[$key].GetType().Name -eq 'String') {
                    $Values += "$key = '$($Data[$key])' AND "
                }
                else {
                    $Values += "$key = $Data[$key] AND "
                }
            }
            $Values = $Values.Replace("AND\s$", "")
            $Query = "SELECT * FROM Sales WHERE $Values"
        }
        if ($DbConnection.State -eq 'Closed') {
            $DbConnection.Open()
        }
        
    }
    PROCESS {
        $Command = $DBConnection.CreateCommand()
        $Command.CommandText = $Query
        $Adapter = New-Object -TypeName System.Data.SQLite.SQLiteDataAdapter $Command
        $Dataset = New-Object -TypeName System.Data.DataSet
        [void]$Adapter.Fill($Dataset)
        return $Dataset.Tables.rows
    }
    END {
        if ($Close) {
            $DbConnection.Close()
        }
    }
    
}

<#
.SYNOPSIS
    Deletes a data record from SQLite database table.
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
function Delete-Data {
    [CmdletBinding()]
    param (
        [Parameter()]
        [system.data.sqlite.sqliteconnection]
        $DbConnection
    )
    BEGIN{


    }
    PROCESS{

    }
    END{

    }
}
<#
.SYNOPSIS
    Updates a data record in a SQLite database table.
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
function Update-Data {
    [CmdletBinding()]
    param (
        [Parameter()]
        [system.data.sqlite.sqliteconnection]
        $DbConnection
    )
    BEGIN{

    }
    PROCESS{

    }
    END{

    }
    
}
<#
.SYNOPSIS
    Remove a table from SQLite database. ****BE CAREFUL this command is irreverisable****.
.DESCRIPTION
    Delete table from SQLite database. This will delete the table including the data inside tables. 
    !!!Practice caution when using this cmdlet, always backup your database before testing against a database file.!!!
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
function Remove-Table {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Data.sqlite.sqliteConnection]
        $DbConnection,
        # Specify table name
        [Parameter(Mandatory = $true)]
        [string[]]
        $TableName
    )
    BEGIN {
        $Query = "DROP TABLE $TableName"
        if ($DbConnection.State -eq 'Closed') {
            $DbConnection.Open()
        }
    }
    PROCESS {
        $Command = $DbConnection.CreateCommand()
        $Command.CommandText = $Query
        $Result = $Command.ExecuteNonQuery()
        return $Result
    }
    END {
        if ($Close) {
            $DbConnection.Close()
        }
    }
    
}

<#
.SYNOPSIS
    Read Pragma values of a SQLite database.
.DESCRIPTION
    This cmdlet returns the pragma value specified by "-Pargma" parameter. 
    For a list of Pragmas you can inspect visit: https://sqlite.org/pragma.html
.EXAMPLE
    PS C:\> Get-Pragma -Pragma busy_timeout
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
function Get-Pragma {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.Data.SQlite.Sqliteconnection]
        $DbConnection,
        # Specify pragma name
        [Parameter(Mandatory=$true)]
        [string]
        $Pragma,
        # Specify if conection should be closed
        [Parameter()]
        [bool]
        $Close
    )

    BEGIN{
        $Query = "PRAGMA $Pragma;"
        if ($DbConnection.State -eq "Closed") {
            $DbConnection.Open()
        }
    }
    PROCESS{
        $Command = $DbConnection.CreateCommand()
        $Command.CommandText = $Query
        $Adapter = New-Object -TypeName System.Data.SQLite.SQLiteDataAdapter $Command
        $PragmaSet = New-Object -TypeName System.Data.DataSet
        [void]$Adapter.Fill($PragmaSet)
        return $PragmaSet.Tables.rows
    }
    END{
        if ($Close) {
            $DbConnection.Close()
        }
    }
    
}

<#
.SYNOPSIS
    Set Pragma value in a SQLite database.
.DESCRIPTION
    
.EXAMPLE
    PS C:\> Set-Pragma -Pragma busy_timeout -Value 23
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
function Set-Pragma {
    [CmdletBinding()]
    param (
        [Parameter()]
        [System.Data.Sqlite.sqliteconnection]
        $DbConnection,
        # Specify pragma name
        [Parameter(Mandatory=$true)]
        [string]
        $Pragma,
        # Specify Pragma value
        [Parameter(Mandatory=$true)]
        [string]
        $Value,
        # Specify if conection should be closed
        [Parameter()]
        [bool]
        $Close
    )

    BEGIN{
        $Query = "PRAGMA $Pragma=$Value;"
        if ($DbConnection.State -eq "Closed") {
            $DbConnection.Open()
        }
    }
    PROCESS{
        $Command = $DbConnection.CreateCommand()
        $Command.CommandText = $Query
        $PargmaResult = $Command.ExecuteNonQuery()
        Return $PargmaResult
    }
    END{
        if ($Close) {
            $DbConnection.Close()
        }
    }
    
}