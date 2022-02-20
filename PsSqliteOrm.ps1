# Add path to the SQLite DLLs. Uncomment line below and change path to where you installed the System.Data.SQLite.dll file
# Add-Type -Path "C:\temp\sqlite.net\System.Data.SQLite.dll"

# Path to MySQL DLLs
# Add-Type -Path "C:\temp\sqlite.net\System.Data.SQLite.dll"

# Path to Postgres .NET DLLs
# Add-Type -Path "C:\temp\sqlite.net\System.Data.SQLite.dll"

# Path to SQL Server .NET DLLs
# Add-Type -Path "C:\temp\sqlite.net\System.Data.SQLite.dll"

<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
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
    Add new table to an empty SQLite datbase
.DESCRIPTION
    Long description
.EXAMPLE
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
    Powershell command to close the database connection.
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> Close-Connection -DbConnection $Connection
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
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
    Powershell command to add rows of data to the database table
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
                $ValueExtract += "'$Value[$item]',"
            }
            else {
                $ValueExtract += "$Value[$item],"
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
    Powershell comdlet to query data from the database
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

function Set-Pragma {
    [CmdletBinding()]
    param (
        [Parameter()]
        [System.Data.Sqlite.sqliteconnection]
        $DbConnection
    )
    
}