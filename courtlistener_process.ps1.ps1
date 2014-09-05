# Powershell for processing courlistener bulk exports without decompressing them or putting the entire file in memory
#
# Usage:
#  $ ./courtlistener_process.ps1 all.xml.gz
#  $ ./courtlistener_process.ps1 scotus.xml.gz
# * filePath: Compressed Courtlistener bulk data file
Param(
  [string]$filePath
)

$gzipFile = new-Object System.IO.FileStream($filePath,[System.IO.FileMode]::Open,[System.IO.FileAccess]::Read,[System.IO.FileShare]::Read)

$zipStream  = new-Object System.IO.Compression.GZipStream($gzipFile,[System.IO.Compression.CompressionMode]::Decompress) 

$xmlReader = [System.Xml.XmlReader]::Create($zipStream)

$xmlReader.MoveToContent() | Out-Null

while( $xmlReader.Read())
{
   if (($xmlReader.NodeType -eq [System.Xml.XmlNodeType]::Element) -and ($xmlReader.Name -eq "opinion"))
   {

        $JSON = "{"
        while($xmlReader.MoveToNextAttribute())
        {
            if(($xmlReader.Name -ne "id") -and ($xmlReader.Name -ne "cited_by"))
            {
                $JSON += "`"$($xmlReader.Name)`":`"$($xmlReader.Value)`","
            } 
            elseif($xmlReader.Name -eq "cited_by")
            {
                $JSON += "`"$($xmlReader.Name)`":[$($xmlReader.Value)],"
            }
        }

        $xmlReader.MoveToContent() | Out-Null
        $JSON+=$xmlReader.ReadElementContentAsString() + "}"
        
        Write-Host $JSON
       
   }
}

