# Introduction

PsSqliteOrm is a powershell module aimed at abstracting SQL operations against a SQLite database. PsSqliteOrm takes attributes from the cmdlets given by the user and tries to construct a SQL command
and then execute the SQL command against the database. This will make CRUD operatios easy to perform
and doesn't require SQL knoweldge to interact with a database.

# How To

## Add SQLite binaries

SQLite provides a .NET assembly to open such database files.

Download the latest version which also fits your >NET version. >NET4.5 is usually preinstalled and a good choice for all Win10 versions.

```powershell
Invoke-WebRequest  -Uri "http://system.data.sqlite.org/blobs/1.0.113.0/sqlite-netFx45-binary-x64-2012-1.0.113.0.zip" -OutFile "C:\temp\sqlite.zip"
mkdir c:\temp\sqlite.net
Expand-Archive c:\temp\sqlite.zip -DestinationPath c:\temp\sqlite.net
```

Load libarary

```powershell
Add-Type -Path "C:\temp\sqlite.net\System.Data.SQLite.dll"
```

Start a new connection to a database file by specifying the path of your DB.

```powershell
$Connection = New-Connection -Path "c:\temp\sqlite\users.db"
```

## Perform CRUD Operations

# Version Control

# Change Log

# License: MIT
