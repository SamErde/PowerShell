################################################################################################
# ADACLScan.ps1
#
# AUTHOR: Robin Granberg (robin.granberg@microsoft.com)
#
# THIS CODE-SAMPLE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR
# FITNESS FOR A PARTICULAR PURPOSE.
#
# This sample is not supported under any Microsoft standard support program or service.
# The script is provided AS IS without warranty of any kind. Microsoft further disclaims all
# implied warranties including, without limitation, any implied warranties of merchantability
# or of fitness for a particular purpose. The entire risk arising out of the use or performance
# of the sample and documentation remains with you. In no event shall Microsoft, its authors,
# or anyone else involved in the creation, production, or delivery of the script be liable for
# any damages whatsoever (including, without limitation, damages for loss of business profits,
# business interruption, loss of business information, or other pecuniary loss) arising out of
# the use of or inability to use the sample or documentation, even if Microsoft has been advised
# of the possibility of such damages.
################################################################################################
<#-------------------------------------------------------------------------------
Version 2.0
October, 2014

New GUI
Progress Bar
Better browsing experiance
Better logging function
Bug fixes
-------------------------------------------------------------------------------
Version 2.0.1
15 October, 2014

Fixed issues related to connecting to ForestDnsZones and DomainDnsZones
-------------------------------------------------------------------------------
Version 2.0.2
28 October, 2014

Fixed issues:
    - Require connection to domain before converting CSV to  HTML, otherwise object GUID translation will fail.
Feature:
    - Scan for SACL's
    - Option to skip Splash through new parameter "NoSplash"
    - Option to show help text through new parameter "Help"
    - Translation of object GUID in CSV file.
-------------------------------------------------------------------------------
Version 2.0.3
29 October, 2014

Fixed issues:
    - PS 2.0 "Where-Object : Cannot bind argument to 'FilterScript' because it is null":5369.

-------------------------------------------------------------------------------#>

param(
[switch]$NoSplash,
[switch]$help)
$strScriptName = $($MyInvocation.MyCommand.Name)

if([threading.thread]::CurrentThread.ApartmentState.ToString() -eq 'MTA')
{
  write-host -ForegroundColor RED "RUN PowerShell.exe with -STA switch"
  write-host -ForegroundColor RED "Example:"
  write-host -ForegroundColor RED "    PowerShell -STA $PSCommandPath"

  Write-Host "Press any key to continue ..."
  $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

  Exit
}

function funHelp()
{
clear
$helpText=@"
THIS CODE-SAMPLE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR
FITNESS FOR A PARTICULAR PURPOSE.

This sample is not supported under any Microsoft standard support program or service.
The script is provided AS IS without warranty of any kind. Microsoft further disclaims all
implied warranties including, without limitation, any implied warranties of merchantability
or of fitness for a particular purpose. The entire risk arising out of the use or performance
of the sample and documentation remains with you. In no event shall Microsoft, its authors,
or anyone else involved in the creation, production, or delivery of the script be liable for
any damages whatsoever (including, without limitation, damages for loss of business profits,
business interruption, loss of business information, or other pecuniary loss) arising out of
the use of or inability to use the sample or documentation, even if Microsoft has been advised

DESCRIPTION:
NAME: $strScriptName


SYSTEM REQUIREMENTS:

- Windows Powershell 2.0

- Connection to an Active Directory Domain



PARAMETERS:

-NoSplash        Skip start flash window.
-help            Prints the HelpFile (Optional)



SYNTAX:
 -------------------------- EXAMPLE 1 --------------------------


.\$strScriptName -NoSplash


 Description
 -----------
 Run the script without Splash window.


 -------------------------- EXAMPLE 2 --------------------------

.\$strScriptName -help

 Description
 -----------
 Displays the help topic for the script



"@
write-host $helpText
exit
}
if ($help){funHelp}
Function BuildSchemaDic
{

$global:dicSchemaIDGUIDs = @{"BF967ABA-0DE6-11D0-A285-00AA003049E2" ="user";`
"BF967A86-0DE6-11D0-A285-00AA003049E2" = "computer";`
"BF967A9C-0DE6-11D0-A285-00AA003049E2" = "group";`
"BF967ABB-0DE6-11D0-A285-00AA003049E2" = "volume";`
"F30E3BBE-9FF0-11D1-B603-0000F80367C1" = "gPLink";`
"F30E3BBF-9FF0-11D1-B603-0000F80367C1" = "gPOptions";`
"BF967AA8-0DE6-11D0-A285-00AA003049E2" = "printQueue";`
"4828CC14-1437-45BC-9B07-AD6F015E5F28" = "inetOrgPerson";`
"5CB41ED0-0E4C-11D0-A286-00AA003049E2" = "contact";`
"BF967AA5-0DE6-11D0-A285-00AA003049E2" = "organizationalUnit";`
"BF967A0A-0DE6-11D0-A285-00AA003049E2" = "pwdLastSet"}


$global:dicSpecialIdentities  = @{"S-1-0"="Null Authority";`
"S-1-0-0"="Nobody";`
"S-1-1"="World Authority";`
"S-1-1-0"="Everyone";`
"S-1-2"="Local Authority";`
"S-1-2-0"="Local ";`
"S-1-2-1"="Console Logon ";`
"S-1-3"="Creator Authority";`
"S-1-3-0"="Creator Owner";`
"S-1-3-1"="Creator Group";`
"S-1-3-2"="Creator Owner Server";`
"S-1-3-3"="Creator Group Server";`
"S-1-3-4"="Owner Rights";`
"S-1-4"="Non-unique Authority";`
"S-1-5"="NT Authority";`
"S-1-5-1"="Dialup";`
"S-1-5-2"="Network";`
"S-1-5-3"="Batch";`
"S-1-5-4"="Interactive";`
"S-1-5-6"="Service";`
"S-1-5-7"="Anonymous";`
"S-1-5-8"="Proxy";`
"S-1-5-9"="Enterprise Domain Controllers";`
"S-1-5-10"="Principal Self";`
"S-1-5-11"="Authenticated Users";`
"S-1-5-12"="Restricted Code";`
"S-1-5-13"="Terminal Server Users";`
"S-1-5-14"="Remote Interactive Logon";`
"S-1-5-15"="This Organization";`
"S-1-5-17"="IUSR";`
"S-1-5-18"="Local System"}

$global:dicNameToSchemaIDGUIDs = @{"user"="BF967ABA-0DE6-11D0-A285-00AA003049E2";`
"computer" = "BF967A86-0DE6-11D0-A285-00AA003049E2";`
"group" = "BF967A9C-0DE6-11D0-A285-00AA003049E2";`
"volume" = "BF967ABB-0DE6-11D0-A285-00AA003049E2";`
"gPLink" = "F30E3BBE-9FF0-11D1-B603-0000F80367C1";`
"gPOptions" = "F30E3BBF-9FF0-11D1-B603-0000F80367C1";`
"printQueue" = "BF967AA8-0DE6-11D0-A285-00AA003049E2";`
"inetOrgPerson" = "4828CC14-1437-45BC-9B07-AD6F015E5F28";`
"contact" = "5CB41ED0-0E4C-11D0-A286-00AA003049E2";`
"organizationalUnit" = "BF967AA5-0DE6-11D0-A285-00AA003049E2";`
"pwdLastSet" = "BF967A0A-0DE6-11D0-A285-00AA003049E2"}
}

BuildSchemaDic

Add-Type -Assembly PresentationFramework

$global:syncHashSplash = [hashtable]::Synchronized(@{})
$newRunspaceSplash =[runspacefactory]::CreateRunspace()
$newRunspaceSplash.ApartmentState = "STA"
$newRunspaceSplash.ThreadOptions = "ReuseThread"
$newRunspaceSplash.Open()
$newRunspaceSplash.SessionStateProxy.SetVariable("global:syncHashSplash",$global:syncHashSplash)
$psCmdSplash = [PowerShell]::Create().AddScript({

[xml]$xamlSplash =
@"
<Window xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:system="clr-namespace:System;assembly=mscorlib"
        WindowStyle='None' AllowsTransparency='True'

        Topmost='True' Background="Transparent"  ShowInTaskbar='False'
         WindowStartupLocation='CenterScreen' >
    <Window.Resources>
        <system:String x:Key="Time">AD ACL &#10;Scanner</system:String>

    </Window.Resources>


    <Grid Height="200" Width="400" Background="White">
        <Border BorderBrush="Black" BorderThickness="1">
        <StackPanel VerticalAlignment="Center">

            <Label x:Name="lbl1"  Content="Active Directory&#10;AD ACL Scanner" FontWeight="Normal" Width="250" Height="110" FontSize="32"  HorizontalAlignment="Center" HorizontalContentAlignment="Center" VerticalContentAlignment="Bottom">
                <Label.Foreground>
                    <LinearGradientBrush>
                        <GradientStop Color="#CC1281DB"/>
                        <GradientStop Color="#FF6797BF" Offset="0.3"/>
                        <GradientStop Color="#FF6797BF" Offset="0.925"/>
                        <GradientStop Color="#FFD4DBE1" Offset="1"/>
                    </LinearGradientBrush>
                </Label.Foreground>
            </Label>
            <Label x:Name="lbl2" Content="THIS CODE-SAMPLE IS PROVIDED WITHOUT WARRANTY OF ANY KIND" Width="500" Height="80" FontSize="10" HorizontalAlignment="Center" HorizontalContentAlignment="Center" VerticalContentAlignment="Bottom">

            </Label>
        </StackPanel>
        </Border>
    </Grid>
</Window>
"@

    $reader=(New-Object System.Xml.XmlNodeReader $xamlSplash)
    $xamlSplash = $null
    Remove-Variable -Name xamlSplash
    $global:syncHashSplash.Window=[Windows.Markup.XamlReader]::Load( $reader )
    $global:syncHashSplash.Window.Show() | Out-Null
    $global:syncHashSplash.Error = $Error
    Start-Sleep -Seconds 3
    $global:syncHashSplash.Window.Dispatcher.Invoke([action]{$global:syncHashSplash.Window.Hide()},"Normal")

    $syncHashSplash = $null
    Remove-Variable -Name "syncHashSplash" -Scope Global
    $reader = $null
    Remove-Variable -Name "reader" -Scope Global
    $newRunspaceSplash = $null
    Remove-Variable -Name "newRunspaceSplash" -Scope Global
})


if (($PSVersionTable.PSVersion -ne "2.0") -and (!$NoSplash))
{
    $psCmdSplash.Runspace = $newRunspaceSplash
    $syncHashSplash = $null
    Remove-Variable -Name "syncHashSplash" -Scope Global
    $dataSplash = $psCmdSplash.BeginInvoke()


}


$ADACLGui = [hashtable]::Synchronized(@{})

$global:intColCount = 15
$global:intDiffCol = 0
$global:myPID = $PID
$HistACLs = New-Object System.Collections.ArrayList
$CurrentFSPath = split-path -parent $MyInvocation.MyCommand.Path
$strLastCacheGuidsDom = ""
$TNRoot = ""
$global:prevNodeText = ""
$sd = ""


[xml]$xamlForm1 = @"
<Window x:Class="WpfApplication1.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="AD ACL Scanner" Height="770" Width="940" WindowStartupLocation="CenterScreen">
    <Window.Background>
        <LinearGradientBrush>
            <LinearGradientBrush.Transform>
                <ScaleTransform x:Name="Scaler" ScaleX="1" ScaleY="1"/>
            </LinearGradientBrush.Transform>
            <GradientStop Color="#CC064A82" Offset="1"/>
            <GradientStop Color="#FF6797BF" Offset="0.7"/>
            <GradientStop Color="#FF6797BF" Offset="0.3"/>
            <GradientStop Color="#FFD4DBE1" Offset="0"/>
        </LinearGradientBrush>
    </Window.Background>
    <Window.Resources>
        <XmlDataProvider x:Name="xmlprov" x:Key="DomainOUData"/>
        <DrawingImage x:Name="FolderImage" x:Key="FolderImage"  >
            <DrawingImage.Drawing>
                <DrawingGroup>
                    <GeometryDrawing Brush="#FF3D85F5">
                        <GeometryDrawing.Geometry>
                            <RectangleGeometry Rect="3,6,32,22" RadiusX="0" RadiusY="0" />
                        </GeometryDrawing.Geometry>
                    </GeometryDrawing>
                    <GeometryDrawing Brush="#FF3D81F5">
                        <GeometryDrawing.Geometry>
                            <RectangleGeometry Rect="18,3,13,5" RadiusX="2" RadiusY="2" />
                        </GeometryDrawing.Geometry>
                    </GeometryDrawing>
                </DrawingGroup>
            </DrawingImage.Drawing>
        </DrawingImage>
        <HierarchicalDataTemplate x:Key="NodeTemplate" ItemsSource="{Binding XPath=OU}">
            <StackPanel Orientation="Horizontal">
                <Image Width="16" Height="16" Stretch="Fill" Source="{Binding XPath=@Img}"/>
                <TextBlock Text="{Binding XPath=@Name}" Margin="2,0,0,0" />
            </StackPanel>
        </HierarchicalDataTemplate>
    </Window.Resources>
    <Grid>
        <Button x:Name="btnExit" Content="Exit" HorizontalAlignment="Left" Margin="835,599,0,0" VerticalAlignment="Top" Width="75"/>
        <GroupBox x:Name="gBoxNCSelect" Grid.Column="0" Header="Select Naming Context" HorizontalAlignment="Left" Height="125" Margin="10,10,0,0" VerticalAlignment="Top" Width="310" BorderBrush="Black">
            <StackPanel Orientation="Vertical" Margin="0,0">
                <StackPanel Orientation="Horizontal">
                    <RadioButton x:Name="rdbDSdef" Content="Domain" HorizontalAlignment="Left" Height="18" Margin="5,10,0,0" VerticalAlignment="Top" Width="65" IsChecked="True"/>
                    <RadioButton x:Name="rdbDSConf" Content="Config" HorizontalAlignment="Left" Height="18" Margin="5,10,0,0" VerticalAlignment="Top" Width="61"/>
                    <RadioButton x:Name="rdbDSSchm" Content="Schema" HorizontalAlignment="Left" Height="18" Margin="5,10,0,0" VerticalAlignment="Top" Width="65"/>
                    <RadioButton x:Name="rdbCustomNC" Content="Custom" HorizontalAlignment="Left" Height="18" Margin="5,10,0,0" VerticalAlignment="Top" Width="65"/>
                </StackPanel>
                <StackPanel Orientation="Vertical" Margin="0,0,0.0,0"  >
                    <Label x:Name="lblDomain" Content="Naming Context:"  HorizontalAlignment="Left" Height="28" Margin="0,0,0,0" Width="231"/>
                    <TextBox x:Name="txtBoxDomainConnect" HorizontalAlignment="Left" Height="18"  Text="rootDSE" Width="285" Margin="0,0,0.0,0" IsEnabled="False"/>
                </StackPanel>
                <StackPanel Orientation="Horizontal"  Margin="0,0,0.0,0"  >
                    <Button x:Name="btnDSConnect" Content="Connect" HorizontalAlignment="Left" Height="23" Margin="0,2,0,0" VerticalAlignment="Top" Width="84"/>
                    <Button x:Name="btnListDdomain" Content="List Domains" HorizontalAlignment="Left" Height="23" Margin="50,2,0,0" VerticalAlignment="Top" Width="95"/>
                </StackPanel>
            </StackPanel>
        </GroupBox>
        <GroupBox x:Name="gBoxBrowse" Grid.Column="0" Header="Browse Options" HorizontalAlignment="Left" Height="51" Margin="10,138,0,0" VerticalAlignment="Top" Width="310" BorderBrush="Black">
            <StackPanel Orientation="Vertical" Margin="0,0">
                <StackPanel Orientation="Horizontal">
                    <RadioButton x:Name="rdbBrowseOU" Content="OU's" HorizontalAlignment="Left" Height="18" Margin="5,10,0,0" VerticalAlignment="Top" Width="61" IsChecked="True"/>
                    <RadioButton x:Name="rdbBrowseAll" Content="All Objects" HorizontalAlignment="Left" Height="18" Margin="20,10,0,0" VerticalAlignment="Top" Width="80"/>
                </StackPanel>
            </StackPanel>
        </GroupBox>
        <GroupBox x:Name="gBoxSelectNodeTreeView" Grid.Column="0" Header="Nodes" HorizontalAlignment="Left" Height="380" Margin="10,190,0,0" VerticalAlignment="Top" Width="310" BorderBrush="Black">
            <StackPanel Orientation="Vertical">
                <TreeView x:Name="treeView1"  Height="350" Width="290"  Margin="5,5,0,5" HorizontalAlignment="Left"
                DataContext="{Binding Source={StaticResource DomainOUData}, XPath=/DomainRoot}"
                ItemTemplate="{StaticResource NodeTemplate}"
                ItemsSource="{Binding}"/>
            </StackPanel>
        </GroupBox>

        <Label x:Name="lblSelectedNode" Content="Selected Object:" HorizontalAlignment="Left" Height="24" Margin="10,570,0,0" VerticalAlignment="Top" Width="158"/>
        <TextBox x:Name="txtBoxSelected" HorizontalAlignment="Left" Height="28" Margin="10,595,0,0" TextWrapping="NoWrap" VerticalAlignment="Top" Width="650"/>
        <ListBox x:Name="TextBoxStatusMessage" DisplayMemberPath="Message" SelectionMode="Extended" HorizontalAlignment="Left" Height="78" Margin="10,643,0,0" VerticalAlignment="Top" Width="650" ScrollViewer.HorizontalScrollBarVisibility="Auto">
            <ListBox.ItemContainerStyle>
                <Style TargetType="{x:Type ListBoxItem}">
                    <Style.Triggers>
                        <DataTrigger Binding="{Binding Path=Type}" Value="Error">
                            <Setter Property="ListBoxItem.Foreground" Value="Red" />
                            <Setter Property="ListBoxItem.Background" Value="LightGray" />
                        </DataTrigger>
                        <DataTrigger Binding="{Binding Path=Type}" Value="Warning">
                            <Setter Property="ListBoxItem.Foreground" Value="Yellow" />
                            <Setter Property="ListBoxItem.Background" Value="Gray" />
                        </DataTrigger>
                        <DataTrigger Binding="{Binding Path=Type}" Value="Info">
                            <Setter Property="ListBoxItem.Foreground" Value="Black" />
                            <Setter Property="ListBoxItem.Background" Value="White" />
                        </DataTrigger>
                    </Style.Triggers>
                </Style>
            </ListBox.ItemContainerStyle>
        </ListBox>
        <Label x:Name="lblStatusBar" Content="Log:" HorizontalAlignment="Left" Height="26" Margin="10,620,0,0" VerticalAlignment="Top" Width="158"/>
        <TabControl x:Name="tabConWiz" HorizontalAlignment="Left" Height="570" Margin="330,10,0,0" VerticalAlignment="Top" Width="580">
            <TabItem x:Name="tabAdv" Header="Advanced" >
                <Grid Background="AliceBlue" HorizontalAlignment="Left" VerticalAlignment="Top" Height="549">
                    <TabControl x:Name="tabScanTop" Background="AliceBlue"  HorizontalAlignment="Left" Height="510"  VerticalAlignment="Top" Width="275">
                        <TabItem x:Name="tabScan" Header="Scan Options" Width="85">
                            <Grid >
                                <StackPanel Orientation="Vertical" Margin="0,0">
                                    <GroupBox x:Name="gBoxScanType" Header="Scan Type" HorizontalAlignment="Left" Height="51" Margin="2,1,0,0" VerticalAlignment="Top" Width="264">
                                        <StackPanel Orientation="Vertical" Margin="0,0">
                                            <StackPanel Orientation="Horizontal">
                                                <RadioButton x:Name="rdbDACL" Content="DACL (Access)" HorizontalAlignment="Left" Height="18" Margin="5,10,0,0" VerticalAlignment="Top" Width="95" IsChecked="True"/>
                                                <RadioButton x:Name="rdbSACL" Content="SACL (Audit)" HorizontalAlignment="Left" Height="18" Margin="20,10,0,0" VerticalAlignment="Top" Width="90"/>

                                            </StackPanel>
                                        </StackPanel>
                                    </GroupBox>
                                    <GroupBox x:Name="gBoxScanDepth" Header="Scan Depth" HorizontalAlignment="Left" Height="51" Margin="2,1,0,0" VerticalAlignment="Top" Width="264">
                                    <StackPanel Orientation="Vertical" Margin="0,0">
                                        <StackPanel Orientation="Horizontal">
                                            <RadioButton x:Name="rdbBase" Content="Base" HorizontalAlignment="Left" Height="18" Margin="5,10,0,0" VerticalAlignment="Top" Width="61" IsChecked="True"/>
                                            <RadioButton x:Name="rdbOneLevel" Content="One Level" HorizontalAlignment="Left" Height="18" Margin="20,10,0,0" VerticalAlignment="Top" Width="80"/>
                                            <RadioButton x:Name="rdbSubtree" Content="Subtree" HorizontalAlignment="Left" Height="18" Margin="20,10,0,0" VerticalAlignment="Top" Width="80"/>
                                        </StackPanel>
                                    </StackPanel>
                                </GroupBox>
                                <GroupBox x:Name="gBoxRdbScan" Header="Objects to scan" HorizontalAlignment="Left" Height="51" Margin="2,0,0,0" VerticalAlignment="Top" Width="264">
                                    <StackPanel Orientation="Vertical" Margin="0,0">
                                        <StackPanel Orientation="Horizontal">
                                            <RadioButton x:Name="rdbScanOU" Content="OUs" HorizontalAlignment="Left" Height="18" Margin="5,10,0,0" VerticalAlignment="Top" Width="61" IsChecked="True"/>
                                            <RadioButton x:Name="rdbScanContainer" Content="Containers" HorizontalAlignment="Left" Height="18" Margin="5,10,0,0" VerticalAlignment="Top" Width="80"/>
                                            <RadioButton x:Name="rdbScanAll" Content="All Objects" HorizontalAlignment="Left" Height="18" Margin="5,10,0,0" VerticalAlignment="Top" Width="80"/>
                                        </StackPanel>
                                    </StackPanel>
                                </GroupBox>
                                <GroupBox x:Name="gBoxReportOpt" Header="View in report" HorizontalAlignment="Left" Height="140" Margin="2,0,0,0" VerticalAlignment="Top" Width="264">
                                    <StackPanel Orientation="Vertical" Margin="0,0">
                                        <StackPanel Orientation="Horizontal">
                                            <CheckBox x:Name="chkBoxGetOwner" Content="View Owner" HorizontalAlignment="Left" Height="18" Margin="5,10,0,0" VerticalAlignment="Top" Width="120"/>
                                            <CheckBox x:Name="chkBoxACLSize" Content="DACL Size" HorizontalAlignment="Left" Height="18" Margin="30,10,0,0" VerticalAlignment="Top" Width="80"/>
                                        </StackPanel>
                                        <StackPanel Orientation="Horizontal" Margin="0,0,0.2,0" Height="40">
                                            <CheckBox x:Name="chkInheritedPerm" Content="Inherited&#10;Permissions" HorizontalAlignment="Left" Height="30" Margin="5,10,0,0" VerticalAlignment="Top" Width="120"/>
                                            <CheckBox x:Name="chkBoxGetOUProtected" Content="Inheritance&#10;Disabled" HorizontalAlignment="Left" Height="30" Margin="30,10,0,0" VerticalAlignment="Top" Width="90"/>
                                        </StackPanel>
                                        <StackPanel Orientation="Horizontal" Height="40" Margin="0,0,0.2,0">
                                                <CheckBox x:Name="chkBoxDefaultPerm" Content="Skip Default&#10;Permissions" HorizontalAlignment="Left" Height="30" Margin="5,10,0,0" VerticalAlignment="Top" Width="120"/>
                                                <CheckBox x:Name="chkBoxReplMeta" Content="SD Modified&#10;date" HorizontalAlignment="Left" Height="30" Margin="30,10,0,0" VerticalAlignment="Top" Width="90"/>
                                        </StackPanel>
                                    </StackPanel>
                                </GroupBox>
                                <GroupBox x:Name="gBoxRdbFile" Header="Output Options" HorizontalAlignment="Left" Height="183" Margin="2,0,0,0" VerticalAlignment="Top" Width="264">
                                    <StackPanel Orientation="Vertical" Margin="0,0">
                                        <StackPanel Orientation="Horizontal">
                                            <RadioButton x:Name="rdbOnlyHTA" Content="HTML" HorizontalAlignment="Left" Height="18" Margin="5,10,0,0" VerticalAlignment="Top" Width="61" GroupName="rdbGroupOutput" IsChecked="True"/>
                                            <RadioButton x:Name="rdbHTAandCSV" Content="HTML and CSV file" HorizontalAlignment="Left" Height="18" Margin="20,10,0,0" VerticalAlignment="Top" Width="155" GroupName="rdbGroupOutput"/>
                                        </StackPanel>
                                        <RadioButton x:Name="rdbOnlyCSV" Content="CSV file" HorizontalAlignment="Left" Height="18" Margin="5,10,0,0" VerticalAlignment="Top" Width="80" GroupName="rdbGroupOutput"/>
                                            <CheckBox x:Name="chkBoxTranslateGUID" Content="Translate GUID's in CSV output" HorizontalAlignment="Left" Height="18" Margin="5,10,0,0" VerticalAlignment="Top" Width="200"/>
                                            <Label x:Name="lblTempFolder" Content="CSV file destination" />
                                        <TextBox x:Name="txtTempFolder" Margin="0,0,0.2,0"/>
                                        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                                            <Button x:Name="btnGetTemplateFolder" Content="Change Folder" />
                                        </StackPanel>
                                    </StackPanel>
                                </GroupBox>
                                    </StackPanel>
                            </Grid>
                        </TabItem>
                        <TabItem x:Name="tabOfflineScan" Header="Additional Options">
                            <Grid>

                                <GroupBox x:Name="gBoxImportCSV" Header="CSV to HTML" HorizontalAlignment="Left" Height="136" Margin="2,1,0,0" VerticalAlignment="Top" Width="264">
                                    <StackPanel Orientation="Vertical" Margin="0,0">
                                        <Label x:Name="lblCSVImport" Content="This file will be converted HTML:" />
                                        <TextBox x:Name="txtCSVImport"/>
                                        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                                            <Button x:Name="btnGetCSVFile" Content="Select CSV" />
                                        </StackPanel>
                                        <CheckBox x:Name="chkBoxTranslateGUIDinCSV" Content="CSV file do not contain object GUIDs" HorizontalAlignment="Left" Height="18" Margin="5,10,0,0" VerticalAlignment="Top" Width="240"/>
                                        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                                            <Button x:Name="btnCreateHTML" Content="Create HTML View" />
                                        </StackPanel>
                                    </StackPanel>
                                </GroupBox>
                            </Grid>
                        </TabItem>
                    </TabControl>
                    <TabControl x:Name="tabFilterTop" Background="AliceBlue"  HorizontalAlignment="Left" Height="510" Margin="280,0,0,0" VerticalAlignment="Top" Width="290">
                        <TabItem x:Name="tabCompare" Header="Compare">
                            <Grid>
                                <StackPanel Orientation="Vertical" Margin="0,0" HorizontalAlignment="Left">

                                        <CheckBox x:Name="chkBoxCompare" Content="Enable Compare" HorizontalAlignment="Left" Margin="5,10,0,0" VerticalAlignment="Top"/>
                                    <Label x:Name="lblCompareDescText" Content="You can compare the current state with  &#10;a previously created CSV file." />
                                    <Label x:Name="lblCompareTemplate" Content="CSV Template File" />
                                    <TextBox x:Name="txtCompareTemplate" Margin="2,0,0,0" Width="275" IsEnabled="False"/>
                                        <StackPanel  Orientation="Horizontal">
                                        <CheckBox x:Name="chkBoxTemplateNodes" Content="Use nodes &#10;from template" HorizontalAlignment="Left" Height="30"   Width="120" Margin="2,5,00,00" IsEnabled="False" />
                                            <Button x:Name="btnGetCompareInput" Content="Select Template" HorizontalAlignment="Right" Height="19" Margin="65,00,00,00" IsEnabled="False"/>
                                        </StackPanel>


                                </StackPanel>
                            </Grid>
                        </TabItem>
                        <TabItem x:Name="tabFilter" Header="Filter">
                            <Grid>
                                <StackPanel Orientation="Vertical" Margin="0,0">
                                    <CheckBox x:Name="chkBoxFilter" Content="Enable Filter" HorizontalAlignment="Left" Margin="5,10,0,0" VerticalAlignment="Top"/>
                                    <Label x:Name="lblAccessCtrl" Content="Filter by Access Type:(example: Allow)" />
                                    <StackPanel Orientation="Horizontal" Margin="0,0">
                                        <CheckBox x:Name="chkBoxType" Content="" HorizontalAlignment="Left" Margin="5,0,0,0" VerticalAlignment="Top" IsEnabled="False"/>
                                        <ComboBox x:Name="combAccessCtrl" HorizontalAlignment="Left" Margin="5,0,0,0" VerticalAlignment="Top" Width="120" IsEnabled="False"/>
                                    </StackPanel>
                                    <Label x:Name="lblFilterExpl" Content="Filter by Object:(example: user)" />
                                    <StackPanel Orientation="Horizontal" Margin="0,0">
                                        <CheckBox x:Name="chkBoxObject" Content="" HorizontalAlignment="Left" Margin="5,0,0,0" VerticalAlignment="Top" IsEnabled="False"/>
                                        <ComboBox x:Name="combObjectFilter" HorizontalAlignment="Left" Margin="5,0,0,0" VerticalAlignment="Top" Width="120" IsEnabled="False"/>
                                    </StackPanel>
                                    <Label x:Name="lblGetObj" Content="The list box contains a few  number of standard &#10;objects. To load all objects from schema &#10;press Load." />
                                    <StackPanel  Orientation="Horizontal" Margin="0,0">

                                        <Label x:Name="lblGetObjExtend" Content="This may take a while!" />
                                        <Button x:Name="btnGetObjFullFilter" Content="Load" IsEnabled="False" Width="50" />
                                    </StackPanel>
                                    <Label x:Name="lblFilterTrusteeExpl" Content="Filter by Trustee:&#10;Examples:&#10;CONTOSO\User&#10;CONTOSO\JohnDoe*&#10;*Smith&#10;*Doe*" />
                                    <StackPanel Orientation="Horizontal" Margin="0,0">
                                        <CheckBox x:Name="chkBoxTrustee" Content="" HorizontalAlignment="Left" Margin="5,0,0,0" VerticalAlignment="Top" IsEnabled="False"/>
                                        <TextBox x:Name="txtFilterTrustee" HorizontalAlignment="Left" Margin="5,0,0,0" VerticalAlignment="Top" Width="120" IsEnabled="False"/>
                                    </StackPanel>
                                </StackPanel>
                            </Grid>
                        </TabItem>
                        <TabItem x:Name="tabEffectiveR" Header="Effective Rights">
                            <Grid >
                                <StackPanel Orientation="Vertical" Margin="0,0">
                                    <CheckBox x:Name="chkBoxEffectiveRights" Content="Enable Effective Rights" HorizontalAlignment="Left" Margin="5,10,0,0" VerticalAlignment="Top"/>
                                    <Label x:Name="lblEffectiveDescText" Content="Effective Access allows you to view the effective &#10;permissions for a user, group, or device account." />
                                    <Label x:Name="lblEffectiveText" Content="Type the account name (samAccountName) for a &#10;user, group or computer" />
                                    <Label x:Name="lblSelectPrincipalDom" Content=":" />
                                    <TextBox x:Name="txtBoxSelectPrincipal" IsEnabled="False"  />
                                    <StackPanel  Orientation="Horizontal" Margin="0,0">
                                        <Button x:Name="btnGetSPAccount" Content="Get Account" Margin="5,0,0,0" IsEnabled="False"/>
                                        <Button x:Name="btnListLocations" Content="Locations..." Margin="50,0,0,0" IsEnabled="False"/>
                                    </StackPanel>
                                    <StackPanel  Orientation="Vertical" Margin="0,0"   >
                                        <GroupBox x:Name="gBoxEffectiveSelUser" Header="Selected Security Principal:" HorizontalAlignment="Left" Height="50" Margin="2,2,0,0" VerticalAlignment="Top" Width="264">
                                            <StackPanel Orientation="Vertical" Margin="0,0">
                                                <Label x:Name="lblEffectiveSelUser" Content="" />
                                            </StackPanel>
                                        </GroupBox>
                                        <Button x:Name="btnGETSPNReport" HorizontalAlignment="Left" Content="View Account" Margin="5,2,0,0" IsEnabled="False" Width="110"/>
                                    </StackPanel>
                                    <CheckBox x:Name="chkBoxEffectiveRightsColor" Content="Show color coded criticality" HorizontalAlignment="Left" Margin="5,10,0,0" VerticalAlignment="Top" IsEnabled="False"/>
                                    <Label x:Name="lblEffectiveRightsColor" Content="Use colors in report to identify criticality level of &#10;permissions.This might help you in implementing &#10;Least-Privilege Administrative Models" />
                                    <Button x:Name="btnViewLegend" Content="View Color Legend" HorizontalAlignment="Left" Margin="5,0,0,0" IsEnabled="False" Width="110"/>
                                </StackPanel>
                            </Grid>
                        </TabItem>

                    </TabControl>
                    <Button x:Name="btnScan" Content="Run Scan" HorizontalAlignment="Left" Height="19" Margin="500,518,0,0" VerticalAlignment="Top" Width="66"/>
                </Grid>
            </TabItem>
        </TabControl>
        <Label x:Name="lblStyleVersion1" Content="AD ACL Scanner &#10;2.0.3 " HorizontalAlignment="Left" Height="40" Margin="750,634,0,0" VerticalAlignment="Top" Width="159" Foreground="#FFF4F0F0" Background="#FF004080" FontWeight="Bold"/>
        <Label x:Name="lblStyleVersion2" Content="written by &#10; robin.granberg@microsoft.com" HorizontalAlignment="Left" Height="40" Margin="750,674,0,0" VerticalAlignment="Top" Width="159" Foreground="#FFF4F0F0" Background="#FF004080" FontSize="10"/>
        <Label x:Name="lblStyleVersion3" Content="L" HorizontalAlignment="Left" Height="38" Margin="708,634,0,0" VerticalAlignment="Top"  Width="40" Background="#FF00AEEF" FontFamily="Webdings" FontSize="36" VerticalContentAlignment="Center" HorizontalContentAlignment="Center" Padding="2,0,0,0"/>
        <Label x:Name="lblStyleVersion4" Content="d" HorizontalAlignment="Left" Height="38" Margin="708,675,0,0" VerticalAlignment="Top"  Width="40" Background="#FFFF5300" FontFamily="Webdings" FontSize="36" VerticalContentAlignment="Center" HorizontalContentAlignment="Center" Padding="2,0,0,0" ScrollViewer.VerticalScrollBarVisibility="Disabled"/>
    </Grid>
</Window>

"@

$xamlForm1.Window.RemoveAttribute("x:Class")

$reader=(New-Object System.Xml.XmlNodeReader  $xamlForm1)
$ADACLGui.Window=[Windows.Markup.XamlReader]::Load( $reader )


$Window = $ADACLGui.Window.FindName("Window")
$xmlprov_adp = $ADACLGui.Window.FindName("xmlprov")
$Img1 = $ADACLGui.Window.FindName("Img1")
$chkBoxTemplateNodes = $ADACLGui.Window.FindName("chkBoxTemplateNodes")
$gBoxReportOpt = $ADACLGui.Window.FindName("gBoxReportOpt")
$gBoxScanDepth = $ADACLGui.Window.FindName("gBoxScanDepth")
$rdbDACL = $ADACLGui.Window.FindName("rdbDACL")
$rdbSACL = $ADACLGui.Window.FindName("rdbSACL")
$gBoxEffectiveSelUser = $ADACLGui.Window.FindName("gBoxEffectiveSelUser")
$lblSelectPrincipalDom = $ADACLGui.Window.FindName("lblSelectPrincipalDom")
$lblEffectiveRightsColor = $ADACLGui.Window.FindName("lblEffectiveRightsColor")
$lblEffectiveSelUser = $ADACLGui.Window.FindName("lblEffectiveSelUser")
$lblEffectiveDescText	 = $ADACLGui.Window.FindName("lblEffectiveDescText	")
$lblEffectiveText = $ADACLGui.Window.FindName("lblEffectiveText")
$chkBoxEffectiveRights = $ADACLGui.Window.FindName("chkBoxEffectiveRights")
$chkBoxEffectiveRightsColor = $ADACLGui.Window.FindName("chkBoxEffectiveRightsColor")
$chkBoxGetOUProtected = $ADACLGui.Window.FindName("chkBoxGetOUProtected")
$chkBoxGetOwner = $ADACLGui.Window.FindName("chkBoxGetOwner")
$chkBoxReplMeta = $ADACLGui.Window.FindName("chkBoxReplMeta")
$chkBoxACLSize = $ADACLGui.Window.FindName("chkBoxACLSize")
$chkBoxType = $ADACLGui.Window.FindName("chkBoxType")
$chkBoxObject = $ADACLGui.Window.FindName("chkBoxObject")
$chkBoxTrustee = $ADACLGui.Window.FindName("chkBoxTrustee")
$lblStyleWin8_1 = $ADACLGui.Window.FindName("lblStyleWin8_1")
$lblStyleWin8_1 = $ADACLGui.Window.FindName("lblStyleWin8_1")
$lblStyleWin8_2 = $ADACLGui.Window.FindName("lblStyleWin8_2")
$lblStyleWin8_3 = $ADACLGui.Window.FindName("lblStyleWin8_3")
$lblStyleWin8_4 = $ADACLGui.Window.FindName("lblStyleWin8_4")
$lblStyleWin8_5 = $ADACLGui.Window.FindName("lblStyleWin8_5")
$lblHeaderInfo = $ADACLGui.Window.FindName("lblHeaderInfo")
$lblRunScan	 = $ADACLGui.Window.FindName("lblRunScan")
$lblConnect	 = $ADACLGui.Window.FindName("lblConnect")
$btnGETSPNReport = $ADACLGui.Window.FindName("btnGETSPNReport")
$btnGetSPAccount = $ADACLGui.Window.FindName("btnGetSPAccount")
$btnGetObjFullFilter = $ADACLGui.Window.FindName("btnGetObjFullFilter")
$btnViewLegend = $ADACLGui.Window.FindName("btnViewLegend")
$tabFilterTop = $ADACLGui.Window.FindName("tabFilterTop")
$tabFilter = $ADACLGui.Window.FindName("tabFilter")
$tabEffectiveR = $ADACLGui.Window.FindName("tabEffectiveR")
$combObjectFilter = $ADACLGui.Window.FindName("combObjectFilter")
$lblGetObj = $ADACLGui.Window.FindName("lblGetObj")
$lblGetObjExtend = $ADACLGui.Window.FindName("lblGetObjExtend")
$lblAccessCtrl = $ADACLGui.Window.FindName("lblAccessCtrl")
$combAccessCtrl = $ADACLGui.Window.FindName("combAccessCtrl")
$lblFilterTrusteeExpl = $ADACLGui.Window.FindName("lblFilterTrusteeExpl")
$txtFilterTrustee = $ADACLGui.Window.FindName("txtFilterTrustee")
$chkBoxFilter = $ADACLGui.Window.FindName("chkBoxFilter")
$lblFilterExpl = $ADACLGui.Window.FindName("lblFilterExpl")
$txtBoxSelectPrincipal = $ADACLGui.Window.FindName("txtBoxSelectPrincipal")
$textBoxResultView	 = $ADACLGui.Window.FindName("textBoxResultView	")
$InitialFormWindowStatePop = $ADACLGui.Window.FindName("InitialFormWindowStatePop")
$form1 = $ADACLGui.Window.FindName("form1")
$txtTempFolder = $ADACLGui.Window.FindName("txtTempFolder")
$lblTempFolder = $ADACLGui.Window.FindName("lblTempFolder")
$txtCompareTemplate = $ADACLGui.Window.FindName("txtCompareTemplate")
$lblCompareTemplate = $ADACLGui.Window.FindName("lblCompareTemplate")
$lblSelectedNode = $ADACLGui.Window.FindName("lblSelectedNode")
$lblStatusBar = $ADACLGui.Window.FindName("lblStatusBar")
$TextBoxStatusMessage = $ADACLGui.Window.FindName("TextBoxStatusMessage")
$lblDomain = $ADACLGui.Window.FindName("lblDomain")
$rdbCustomNC = $ADACLGui.Window.FindName("rdbCustomNC")
$rdbOneLevel = $ADACLGui.Window.FindName("rdbOneLevel")
$rdbSubtree = $ADACLGui.Window.FindName("rdbSubtree")
$rdbDSdef = $ADACLGui.Window.FindName("rdbDSdef")
$rdbDSConf = $ADACLGui.Window.FindName("rdbDSConf")
$rdbDSSchm = $ADACLGui.Window.FindName("rdbDSSchm")
$btnDSConnect = $ADACLGui.Window.FindName("btnDSConnect")
$btnListDdomain = $ADACLGui.Window.FindName("btnListDdomain")
$btnListLocations = $ADACLGui.Window.FindName("btnListLocations")
$gBoxRdbScan = $ADACLGui.Window.FindName("gBoxRdbScan")
$gBoxRdbFile = $ADACLGui.Window.FindName("gBoxRdbFile")
$tabScanTop = $ADACLGui.Window.FindName("tabScanTop")
$tabScan = $ADACLGui.Window.FindName("tabScan")
$tabOfflineScan = $ADACLGui.Window.FindName("tabOfflineScan")
$txtCSVImport = $ADACLGui.Window.FindName("txtCSVImport")
$lblCSVImport = $ADACLGui.Window.FindName("lblCSVImport")
$rdbBase = $ADACLGui.Window.FindName("rdbBase")
$chkInheritedPerm = $ADACLGui.Window.FindName("chkInheritedPerm")
$chkBoxDefaultPerm = $ADACLGui.Window.FindName("chkBoxDefaultPerm")
$rdbScanOU = $ADACLGui.Window.FindName("rdbScanOU")
$rdbScanContainer = $ADACLGui.Window.FindName("rdbScanContainer")
$rdbScanAll = $ADACLGui.Window.FindName("rdbScanAll")
$rdbHTAandCSV = $ADACLGui.Window.FindName("rdbHTAandCSV")
$rdbOnlyHTA = $ADACLGui.Window.FindName("rdbOnlyHTA")
$rdbOnlyCSV = $ADACLGui.Window.FindName("rdbOnlyCSV")
$chkBoxExplicit = $ADACLGui.Window.FindName("chkBoxExplicit")
$btnConfig = $ADACLGui.Window.FindName("btnConfig")
$txtBoxSelected = $ADACLGui.Window.FindName("txtBoxSelected")
$txtBoxDomainConnect = $ADACLGui.Window.FindName("txtBoxDomainConnect")
$gBoxNCSelect = $ADACLGui.Window.FindName("gBoxNCSelect")
$gBoxBrowse = $ADACLGui.Window.FindName("gBoxBrowse")
$rdbBrowseAll = $ADACLGui.Window.FindName("rdbBrowseAll")
$rdbBrowseOU = $ADACLGui.Window.FindName("rdbBrowseOU")
$btnScan = $ADACLGui.Window.FindName("btnScan")
$lblHeader = $ADACLGui.Window.FindName("lblHeader")
$treeView1 = $ADACLGui.Window.FindName("treeView1")
$chkBoxCompare = $ADACLGui.Window.FindName("chkBoxCompare")
$btnGetTemplateFolder = $ADACLGui.Window.FindName("btnGetTemplateFolder")
$btnGetCompareInput = $ADACLGui.Window.FindName("btnGetCompareInput")
$btnExit = $ADACLGui.Window.FindName("btnExit")
$btnGetCSVFile = $ADACLGui.Window.FindName("btnGetCSVFile")
$InitialFormWindowState = $ADACLGui.Window.FindName("InitialFormWindowState")
$gBoxCompare = $ADACLGui.Window.FindName("gBoxCompare")
$gBoxImportCSV = $ADACLGui.Window.FindName("gBoxImportCSV")
$btnViewLegened = $ADACLGui.Window.FindName("btnViewLegened")
$btnCreateHTML = $ADACLGui.Window.FindName("btnCreateHTML")
$chkBoxTranslateGUID = $ADACLGui.Window.FindName("chkBoxTranslateGUID")
$chkBoxTranslateGUIDinCSV = $ADACLGui.Window.FindName("chkBoxTranslateGUIDinCSV")

$txtTempFolder.Text = $CurrentFSPath
$global:bolConnected = $false
$global:strPinDomDC = ""
$global:strPrinDomAttr = ""
$global:strPrinDomDir = ""
$global:strPrinDomFlat = ""
$global:strPrincipalDN =""
 $global:strDomainPrinDNName = ""
$global:strEffectiveRightSP = ""
$global:strEffectiveRightAccount = ""
$global:strSPNobjectClass = ""
$global:tokens = New-Object System.Collections.ArrayList
$global:tokens.Clear()
$global:strDommainSelect = "rootDSE"
$global:bolTempValue_InhertiedChkBox = $false
$global:scopeLevel = "OneLevel"
$global:intWizState = 0
[void]$combAccessCtrl.Items.Add("Allow")
[void]$combAccessCtrl.Items.Add("Deny")

###################
#TODO: Place custom script here
#Add-Type -TypeDefinition @"

$code = @"
using System;
using System.Drawing;
using System.Runtime.InteropServices;

namespace System
{
	public class IconExtractor
	{

	 public static Icon Extract(string file, int number, bool largeIcon)
	 {
	  IntPtr large;
	  IntPtr small;
	  ExtractIconEx(file, number, out large, out small, 1);
	  try
	  {
	   return Icon.FromHandle(largeIcon ? large : small);
	  }
	  catch
	  {
	   return null;
	  }

	 }
	 [DllImport("Shell32.dll", EntryPoint = "ExtractIconExW", CharSet = CharSet.Unicode, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
	 private static extern int ExtractIconEx(string sFile, int iIndex, out IntPtr piLargeVersion, out IntPtr piSmallVersion, int amountIcons);

	}
}
"@
Add-Type -TypeDefinition $code -ReferencedAssemblies System.Drawing


$ADACLGui.Window.Add_Loaded({
    $Global:observableCollection = New-Object System.Collections.ObjectModel.ObservableCollection[System.Object]
    $TextBoxStatusMessage.ItemsSource = $Global:observableCollection
})


Add-Type @"
  using System;
  using System.Runtime.InteropServices;
  public class SFW {
     [DllImport("user32.dll")]
     [return: MarshalAs(UnmanagedType.Bool)]
     public static extern bool SetForegroundWindow(IntPtr hWnd);
  }
"@

[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null



$btnGETSPNReport.add_Click(
{
        If(($global:strEffectiveRightSP -ne "") -and  ($global:tokens.count -gt 0))
    {

        $strFileSPNHTA = $env:temp + "\SPNHTML.hta"
	    $strFileSPNHTM = $env:temp + "\"+"$global:strEffectiveRightAccount"+".htm"
        CreateServicePrincipalReportHTA $global:strEffectiveRightSP $strFileSPNHTA $strFileSPNHTM $CurrentFSPath
        CreateSPNHTM $global:strEffectiveRightSP $strFileSPNHTM
        InitiateSPNHTM $strFileSPNHTA

        WriteSPNHTM $global:strEffectiveRightSP $global:tokens $global:strSPNobjectClass $($global:tokens.count-1) $strColorTemp $strFileSPNHTA $strFileSPNHTM
        Invoke-Item $strFileSPNHTA
    }
    else
    {
        $global:observableCollection.Insert(0,(LogMessage -strMessage "No service principal selected!" -strType "Error" -DateStamp ))

    }
})

$btnViewLegend.add_Click(
{

        $strFileLegendHTA = $env:temp + "\LegendHTML.hta"

        CreateColorLegenedReportHTA $strFileLegendHTA
        Invoke-Item $strFileLegendHTA

})

$btnGetSPAccount.add_Click(
{

    if ($global:bolConnected -eq $true)
    {

        If (!($txtBoxSelectPrincipal.Text -eq ""))
        {
            GetEffectiveRightSP $txtBoxSelectPrincipal.Text $global:strDomainPrinDNName
        }
        else
        {
            $global:observableCollection.Insert(0,(LogMessage -strMessage "Enter a principal name!" -strType "Error" -DateStamp ))
        }
    }
        else
    {
        $global:observableCollection.Insert(0,(LogMessage -strMessage "Connect to your naming context first!" -strType "Error" -DateStamp ))
    }
})



$btnListDdomain.add_Click(
{

GenerateDomainPicker

$txtBoxDomainConnect.Text = $global:strDommainSelect

})

$btnListLocations.add_Click(
{

    if ($global:bolConnected -eq $true)
    {
        GenerateTrustedDomainPicker
    }
        else
    {
        $global:observableCollection.Insert(0,(LogMessage -strMessage "Connect to your naming context first!" -strType "Error" -DateStamp ))
    }
})
$rdbDACL.add_Click(
{

    If($rdbDACL.IsChecked)
    {

        #if ($global:bolTempValue_chkBoxCompare -ne $null)
        #{
        #$chkBoxCompare.IsChecked = $global:bolTempValue_chkBoxCompare
        #}
        $chkBoxCompare.IsEnabled = $true

     }


})
$rdbSACL.add_Click(
{

    If($rdbSACL.IsChecked)
    {

        #$global:bolTempValue_chkBoxCompare = $chkBoxCompare.IsChecked
        $chkBoxCompare.IsChecked = $false
        $chkBoxCompare.IsEnabled = $false

     }


})
$chkBoxCompare.add_Click(
{
    If($chkBoxCompare.IsChecked)
    {
        if ($global:bolTempValue_InhertiedChkBox -ne $null)
        {
        $chkInheritedPerm.IsChecked = $global:bolTempValue_InhertiedChkBox
        }

        if ($global:bolTempValue_chkBoxGetOwner -ne $null)
        {
        $chkBoxGetOwner.IsChecked = $global:bolTempValue_chkBoxGetOwner
        }

        $chkInheritedPerm.IsEnabled = $true
        $chkBoxGetOwner.IsEnabled = $true

        $txtCompareTemplate.IsEnabled = $true
        $chkBoxTemplateNodes.IsEnabled = $true
        $btnGetCompareInput.IsEnabled = $true

        $chkBoxFilter.IsChecked = $false
        $chkBoxEffectiveRights.IsChecked = $false
        $txtBoxSelectPrincipal.IsEnabled = $false
        $btnGetSPAccount.IsEnabled = $false
        $btnListLocations.IsEnabled = $false
        $btnGETSPNReport.IsEnabled = $false
        $btnViewLegend.IsEnabled = $false
        $chkBoxEffectiveRightsColor.IsEnabled = $false
        $chkBoxType.IsEnabled = $false
        $chkBoxObject.IsEnabled = $false
        $chkBoxTrustee.IsEnabled =  $false
        $chkBoxType.IsChecked = $false
        $chkBoxObject.IsChecked = $false
        $chkBoxTrustee.IsChecked =  $false
        $combObjectFilter.IsEnabled = $false
        $txtFilterTrustee.IsEnabled = $false
        $combAccessCtrl.IsEnabled = $false
        $btnGetObjFullFilter.IsEnabled = $false

    }
    else
    {

        $txtCompareTemplate.IsEnabled = $false
        $chkBoxTemplateNodes.IsEnabled = $false
        $btnGetCompareInput.IsEnabled = $false

    }

})
$chkBoxEffectiveRights.add_Click(
{
    If($chkBoxEffectiveRights.IsChecked)
    {

        $global:bolTempValue_InhertiedChkBox = $chkInheritedPerm.IsChecked
        $global:bolTempValue_chkBoxGetOwner = $chkBoxGetOwner.IsChecked
        $chkBoxFilter.IsChecked = $false
        $chkBoxCompare.IsChecked = $false
        $txtBoxSelectPrincipal.IsEnabled = $true
        $btnGetSPAccount.IsEnabled = $true
        $btnListLocations.IsEnabled = $true
        $btnGETSPNReport.IsEnabled = $true
        $chkInheritedPerm.IsEnabled = $false
        $chkInheritedPerm.IsChecked = $true
        $chkBoxGetOwner.IsEnabled = $false
        $btnViewLegend.IsEnabled = $true
        $chkBoxGetOwner.IsChecked= $true
        $chkBoxEffectiveRightsColor.IsEnabled = $true
        $chkBoxType.IsEnabled = $false
        $chkBoxObject.IsEnabled = $false
        $chkBoxTrustee.IsEnabled =  $false
        $chkBoxType.IsChecked = $false
        $chkBoxObject.IsChecked = $false
        $chkBoxTrustee.IsChecked =  $false
        $combObjectFilter.IsEnabled = $false
        $txtFilterTrustee.IsEnabled = $false
        $combAccessCtrl.IsEnabled = $false
        $btnGetObjFullFilter.IsEnabled = $false

    }
    else
    {

     $txtBoxSelectPrincipal.IsEnabled = $false
     $chkBoxEffectiveRightsColor.IsEnabled = $false
     $chkBoxEffectiveRightsColor.IsChecked = $false
     $btnGetSPAccount.IsEnabled = $false
     $btnListLocations.IsEnabled = $false
     $btnGETSPNReport.IsEnabled = $false
     $btnViewLegend.IsEnabled = $false
     $chkInheritedPerm.IsEnabled = $true
     $chkInheritedPerm.IsChecked = $global:bolTempValue_InhertiedChkBox
    $chkBoxGetOwner.IsEnabled = $true
    $chkBoxGetOwner.IsChecked = $global:bolTempValue_chkBoxGetOwner
    }

})


$chkBoxFilter.add_Click(
{


    If($chkBoxFilter.IsChecked -eq $true)
    {
        $chkBoxCompare.IsChecked = $false
        $chkBoxEffectiveRights.IsChecked = $false
        $chkBoxType.IsEnabled = $true
        $chkBoxObject.IsEnabled = $true
        $chkBoxTrustee.IsEnabled =  $true
        $combObjectFilter.IsEnabled = $true
        $txtFilterTrustee.IsEnabled = $true
        $combAccessCtrl.IsEnabled = $true
        $btnGetObjFullFilter.IsEnabled = $true
        $txtBoxSelectPrincipal.IsEnabled = $false
        $chkBoxEffectiveRightsColor.IsEnabled = $false
        $chkBoxEffectiveRightsColor.IsChecked = $false
        $btnGetSPAccount.IsEnabled = $false
        $btnListLocations.IsEnabled = $false
        $btnGETSPNReport.IsEnabled = $false
        $btnViewLegend.IsEnabled = $false
        $chkInheritedPerm.IsEnabled = $true
        $chkInheritedPerm.IsChecked = $global:bolTempValue_InhertiedChkBox
        $chkBoxGetOwner.IsEnabled = $true
        if ($global:bolTempValue_chkBoxGetOwner -ne $null)
        {
            $chkBoxGetOwner.IsChecked = $global:bolTempValue_chkBoxGetOwner
        }

    }
    else
    {
        $chkBoxType.IsEnabled = $false
        $chkBoxObject.IsEnabled = $false
        $chkBoxTrustee.IsEnabled =  $false
        $chkBoxType.IsChecked = $false
        $chkBoxObject.IsChecked = $false
        $chkBoxTrustee.IsChecked =  $false
        $combObjectFilter.IsEnabled = $false
        $txtFilterTrustee.IsEnabled = $false
        $combAccessCtrl.IsEnabled = $false
        $btnGetObjFullFilter.IsEnabled = $false
}
})

$rdbDSSchm.add_Click(
{
    If($rdbCustomNC.IsChecked -eq $true)
    {
        $txtBoxDomainConnect.IsEnabled = $true
        $btnListDdomain.IsEnabled = $false
        if (($txtBoxDomainConnect.Text -eq "rootDSE") -or ($txtBoxDomainConnect.Text -eq "config") -or ($txtBoxDomainConnect.Text -eq "schema"))
        {
        $txtBoxDomainConnect.Text = ""
        }
    }
    else
    {
    $btnListDdomain.IsEnabled = $false
     If($rdbDSdef.IsChecked -eq $true)
    {
        $txtBoxDomainConnect.Text = $global:strDommainSelect
        $btnListDdomain.IsEnabled = $true

    }
     If($rdbDSConf.IsChecked -eq $true)
    {
        $txtBoxDomainConnect.Text = "config"


    }
     If($rdbDSSchm.IsChecked -eq $true)
    {
        $txtBoxDomainConnect.Text = "schema"


    }
    $txtBoxDomainConnect.IsEnabled = $false
    }



})

$rdbDSConf.add_Click(
{
    If($rdbCustomNC.IsChecked -eq $true)
    {
        $txtBoxDomainConnect.IsEnabled = $true
        $btnListDdomain.IsEnabled = $false
        if (($txtBoxDomainConnect.Text -eq "rootDSE") -or ($txtBoxDomainConnect.Text -eq "config") -or ($txtBoxDomainConnect.Text -eq "schema"))
        {
        $txtBoxDomainConnect.Text = ""
        }
    }
    else
    {
    $btnListDdomain.IsEnabled = $false
     If($rdbDSdef.IsChecked -eq $true)
    {
        $txtBoxDomainConnect.Text = $global:strDommainSelect
        $btnListDdomain.IsEnabled = $true

    }
     If($rdbDSConf.IsChecked -eq $true)
    {
        $txtBoxDomainConnect.Text = "config"


    }
     If($rdbDSSchm.IsChecked -eq $true)
    {
        $txtBoxDomainConnect.Text = "schema"


    }
    $txtBoxDomainConnect.IsEnabled = $false
    }



})



$rdbDSdef.add_Click(
{
    If($rdbCustomNC.IsChecked -eq $true)
    {
        $txtBoxDomainConnect.IsEnabled = $true
        $btnListDdomain.IsEnabled = $false
        if (($txtBoxDomainConnect.Text -eq "rootDSE") -or ($txtBoxDomainConnect.Text -eq "config") -or ($txtBoxDomainConnect.Text -eq "schema"))
        {
        $txtBoxDomainConnect.Text = ""
        }
    }
    else
    {
    $btnListDdomain.IsEnabled = $false
     If($rdbDSdef.IsChecked -eq $true)
    {
        $txtBoxDomainConnect.Text = $global:strDommainSelect
        $btnListDdomain.IsEnabled = $true

    }
     If($rdbDSConf.IsChecked -eq $true)
    {
        $txtBoxDomainConnect.Text = "config"


    }
     If($rdbDSSchm.IsChecked -eq $true)
    {
        $txtBoxDomainConnect.Text = "schema"


    }
    $txtBoxDomainConnect.IsEnabled = $false
    }



})


$rdbCustomNC.add_Click(
{
    If($rdbCustomNC.IsChecked -eq $true)
    {
        $txtBoxDomainConnect.IsEnabled = $true
        $btnListDdomain.IsEnabled = $false
        if (($txtBoxDomainConnect.Text -eq "rootDSE") -or ($txtBoxDomainConnect.Text -eq "config") -or ($txtBoxDomainConnect.Text -eq "schema"))
        {
        $txtBoxDomainConnect.Text = ""
        }
    }
    else
    {
    $btnListDdomain.IsEnabled = $false
     If($rdbDSdef.IsChecked -eq $true)
    {
        $txtBoxDomainConnect.Text = $global:strDommainSelect
        $btnListDdomain.IsEnabled = $true

    }
     If($rdbDSConf.IsChecked -eq $true)
    {
        $txtBoxDomainConnect.Text = "config"


    }
     If($rdbDSSchm.IsChecked -eq $true)
    {
        $txtBoxDomainConnect.Text = "schema"


    }
    $txtBoxDomainConnect.IsEnabled = $false
    }



})

$btnGetTemplateFolder.add_Click(
{

$strFolderPath = Select-Folder
$txtTempFolder.Text = $strFolderPath


})
$btnGetCompareInput.add_Click(
{

$strFilePath = Select-File
$txtCompareTemplate.Text = $strFilePath


})
$btnGetCSVFile.add_Click(
{

$strFilePath = Select-File

$txtCSVImport.Text = $strFilePath


})
$btnDSConnect.add_Click(
{

$global:bolRoot = $true
#$treeView1.Items.Clear()
$NCSelect = $false
	If ($rdbDSConf.IsChecked)
	{

        [directoryservices.directoryEntry]$root = (New-Object system.directoryservices.directoryEntry)

        # Try to connect to the Domain root
        &{#Try
        [void]$Root.psbase.get_Name()}
        Trap [SystemException]
        {[boolean] $global:bolRoot = $false
            $global:observableCollection.Insert(0,(LogMessage -strMessage "Failed! Domain does not exist or can not be connected" -strType "Error" -DateStamp ))
            $global:bolConnected = $false; Continue
        }

        if ($global:bolRoot -eq $true)
        {
        $arrADPartitions = GetADPartitions($root.distinguishedName)
        [string] $global:strDomainDNName = $arrADPartitions.Item("domain")
        $global:strDomainPrinDNName = $global:strDomainDNName
        $global:strDomainLongName = $global:strDomainDNName.Replace("DC=","")
        $global:strDomainLongName = $global:strDomainLongName.Replace(",",".")

        $Context = New-Object DirectoryServices.ActiveDirectory.DirectoryContext("Domain",$global:strDomainLongName )
        $ojbDomain = [DirectoryServices.ActiveDirectory.Domain]::GetDomain($Context)
        $global:strDC = $($ojbDomain.FindDomainController()).name
        $global:Forest = Get-Forest $global:strDC
        $global:ForestRootDomainDN = Get-DomainDNfromFQDN $global:Forest.RootDomain
        $global:strDomainShortName = GetDomainShortName $global:strDomainDNName $global:ForestRootDomainDN

        $lblSelectPrincipalDom.Content = $global:strDomainShortName+":"
        $NCSelect = $true


        $global:observableCollection.Insert(0,(LogMessage -strMessage "Connected" -strType "Info" -DateStamp ))

        $root = New-Object system.directoryservices.directoryEntry("LDAP://$global:strDC/cn=configuration,"+$global:ForestRootDomainDN)

        }
	}
	If ($rdbDSSchm.IsChecked)
	{
        [directoryservices.directoryEntry]$root = (New-Object system.directoryservices.directoryEntry)

        # Try to connect to the Domain root
        &{#Try
        [void]$Root.psbase.get_Name()}
        Trap [SystemException]
        {[boolean] $global:bolRoot = $false
            $global:observableCollection.Insert(0,(LogMessage -strMessage "Failed! Domain does not exist or can not be connected" -strType "Error" -DateStamp ))
            $global:bolConnected = $false; Continue
        }
        if ($global:bolRoot -eq $true)
        {
        $arrADPartitions = GetADPartitions($root.distinguishedName)
        [string] $global:strDomainDNName = $arrADPartitions.Item("domain")
        $global:strDomainPrinDNName = $global:strDomainDNName
        $global:strDomainLongName = $global:strDomainDNName.Replace("DC=","")
        $global:strDomainLongName = $global:strDomainLongName.Replace(",",".")

        $Context = New-Object DirectoryServices.ActiveDirectory.DirectoryContext("Domain",$global:strDomainLongName )
        $ojbDomain = [DirectoryServices.ActiveDirectory.Domain]::GetDomain($Context)
        $global:strDC = $($ojbDomain.FindDomainController()).name
        $global:Forest = Get-Forest $global:strDC
        $global:ForestRootDomainDN = Get-DomainDNfromFQDN $global:Forest.RootDomain
        $global:strDomainShortName = GetDomainShortName $global:strDomainDNName $global:ForestRootDomainDN
        $lblSelectPrincipalDom.Content = $global:strDomainShortName+":"
        $NCSelect = $true


        $global:observableCollection.Insert(0,(LogMessage -strMessage "Connected" -strType "Info" -DateStamp ))

        $root = New-Object system.directoryservices.directoryEntry("LDAP://$global:strDC/cn=schema,cn=configuration,"+$global:ForestRootDomainDN)

        }
	}
	If ($rdbDSdef.IsChecked)
	{
       if (!($txtBoxDomainConnect.Text -eq "rootDSE"))
        {

            $strNamingContextDN = $txtBoxDomainConnect.Text
            If(CheckDNExist $strNamingContextDN)
            {
                $root = New-Object system.directoryservices.directoryEntry("LDAP://"+$strNamingContextDN)
                $global:strDomainDNName = $root.distinguishedName.tostring()
                $global:strDomainPrintDNName = $global:strDomainDNName
                $global:strDomainLongName = $global:strDomainDNName.Replace("DC=","")
                $global:strDomainLongName = $global:strDomainLongName.Replace(",",".")


                $Context = New-Object DirectoryServices.ActiveDirectory.DirectoryContext("Domain",$global:strDomainLongName )
                $ojbDomain = [DirectoryServices.ActiveDirectory.Domain]::GetDomain($Context)
                $global:strDC = $($ojbDomain.FindDomainController()).name
                $global:Forest = Get-Forest $global:strDC
                $global:ForestRootDomainDN = Get-DomainDNfromFQDN $global:Forest.RootDomain
                $global:strDomainShortName = GetDomainShortName $global:strDomainDNName $global:ForestRootDomainDN
                $lblSelectPrincipalDom.Content = $global:strDomainShortName+":"
                $NCSelect = $true
            }
           else
            {
               $global:observableCollection.Insert(0,(LogMessage -strMessage "Failed! Domain does not exist or can not be connected" -strType "Error" -DateStamp ))
               $global:bolConnected = $false
            }
        }
        else
        {

            [directoryservices.directoryEntry]$root = (New-Object system.directoryservices.directoryEntry)

            # Try to connect to the Domain root
            &{#Try
            [void]$Root.psbase.get_Name()}
            Trap [SystemException]
            {[boolean] $global:bolRoot = $false

                $global:observableCollection.Insert(0,(LogMessage -strMessage "Failed! Domain does not exist or can not be connected" -strType "Error" -DateStamp ))
                $global:bolConnected = $false; Continue
            }
            if ($global:bolRoot -eq $true)
            {

            $arrADPartitions = GetADPartitions($root.distinguishedName)
            [string] $global:strDomainDNName = $arrADPartitions.Item("domain")
            $global:strDomainPrinDNName = $global:strDomainDNName
            $global:strDomainLongName = $global:strDomainDNName.Replace("DC=","")
            $global:strDomainLongName = $global:strDomainLongName.Replace(",",".")

            $Context = New-Object DirectoryServices.ActiveDirectory.DirectoryContext("Domain",$global:strDomainLongName )
            $ojbDomain = [DirectoryServices.ActiveDirectory.Domain]::GetDomain($Context)
            $global:strDC = $($ojbDomain.FindDomainController()).name
            $global:Forest = Get-Forest $global:strDC

            $global:ForestRootDomainDN = Get-DomainDNfromFQDN $global:Forest.RootDomain
            $global:strDomainShortName = GetDomainShortName $global:strDomainDNName $global:ForestRootDomainDN
            $lblSelectPrincipalDom.Content = $global:strDomainShortName+":"


            $global:observableCollection.Insert(0,(LogMessage -strMessage "Connected" -strType "Info" -DateStamp ))
            $strNamingContextDN = $root.distinguishedName

            $NCSelect = $true

            }
        }
	}
	If ($rdbCustomNC.IsChecked)
	{
        if ($txtBoxDomainConnect.Text.Length -gt 0)
        {
            $strNamingContextDN = $txtBoxDomainConnect.Text
           If(CheckDNExist $strNamingContextDN)
           {
                $root = New-Object system.directoryservices.directoryEntry("LDAP://"+$strNamingContextDN)
                if (($root.distinguishedName.tostring() -match "cn=") -or ($root.distinguishedName.tostring() -match "ou="))
                {
                    $global:strDomainDNName = Get-DomainDN $root.distinguishedName.tostring()
                }
                else
                {
                    $global:strDomainDNName = $root.distinguishedName.tostring()
                }

                if ($global:strDomainDNName -match "DC=DomainDnsZones,")
                {
                    $global:strDomainDNName = $global:strDomainDNName.Replace("DC=DomainDnsZones,","")
                }
                  if ($global:strDomainDNName -match "DC=ForestDnsZones,")
                {
                    $global:strDomainDNName = $global:strDomainDNName.Replace("DC=ForestDnsZones,","")
                }



                $global:strDomainPrinDNName = $global:strDomainDNName

                $global:strDomainLongName = $global:strDomainDNName.Replace("DC=","")
                $global:strDomainLongName = $global:strDomainLongName.Replace(",",".")

                $Context = New-Object DirectoryServices.ActiveDirectory.DirectoryContext("Domain",$global:strDomainLongName )
                $ojbDomain = [DirectoryServices.ActiveDirectory.Domain]::GetDomain($Context)
                $global:strDC  = $($ojbDomain.FindDomainController()).name
                $global:Forest = Get-Forest $global:strDC
                $global:ForestRootDomainDN = Get-DomainDNfromFQDN $global:Forest.RootDomain

                $global:strDomainShortName = GetDomainShortName $global:strDomainDNName $global:ForestRootDomainDN
                $lblSelectPrincipalDom.Content = $global:strDomainShortName+":"

                $global:observableCollection.Insert(0,(LogMessage -strMessage "Connected" -strType "Info" -DateStamp ))
                $strNamingContextDN = $root.distinguishedName

                $NCSelect = $true
           }
           else
           {
               $global:observableCollection.Insert(0,(LogMessage -strMessage "Failed! Domain does not exist or can not be connected" -strType "Error" -DateStamp ))
               $global:bolConnected = $false
           }
        }
        else
        {
               $global:observableCollection.Insert(0,(LogMessage -strMessage "Failed! No naming context specified!" -strType "Error" -DateStamp ))
               $global:bolConnected = $false
        }
	}
    If ($NCSelect -eq $true)
    {
	If (!($strLastCacheGuidsDom -eq $global:strDomainDNName))
	{
	    $global:dicRightsGuids = @{"Seed" = "xxx"}
	    CacheRightsGuids $global:strDomainDNName
	    $strLastCacheGuidsDom = $global:strDomainDNName


	}



    $xml = Get-XMLDomainOUTree $root.distinguishedName.tostring()
        # Change XML Document, XPath and Refresh
    $xmlprov_adp.Document = $xml
    $xmlProv_adp.XPath = "/DomainRoot"
    $xmlProv_adp.Refresh()


    $global:bolConnected = $true

    If (!(Test-Path ($env:temp + "\OU.png")))
    {
    (([System.IconExtractor]::Extract("mmcndmgr.dll", 0, $true)).ToBitMap()).Save($env:temp + "\OU.png")
    }
    If (!(Test-Path ($env:temp + "\Expand.png")))
    {
    (([System.IconExtractor]::Extract("mmcndmgr.dll", 6, $true)).ToBitMap()).Save($env:temp + "\Expand.png")
    }
    If (!(Test-Path ($env:temp + "\User.png")))
    {
    (([System.IconExtractor]::Extract("mmcndmgr.dll", 58, $true)).ToBitMap()).Save($env:temp + "\User.png")
    }
    If (!(Test-Path ($env:temp + "\Group.png")))
    {
    (([System.IconExtractor]::Extract("mmcndmgr.dll", 59, $true)).ToBitMap()).Save($env:temp + "\Group.png")
    }
    If (!(Test-Path ($env:temp + "\Computer.png")))
    {
    (([System.IconExtractor]::Extract("mmcndmgr.dll", 60, $true)).ToBitMap()).Save($env:temp + "\Computer.png")
    }
    If (!(Test-Path ($env:temp + "\Container.png")))
    {
    (([System.IconExtractor]::Extract("mmcndmgr.dll", 66, $true)).ToBitMap()).Save($env:temp + "\Container.png")
    }
    If (!(Test-Path ($env:temp + "\DomainDNS.png")))
    {
    (([System.IconExtractor]::Extract("mmcndmgr.dll", 95, $true)).ToBitMap()).Save($env:temp + "\DomainDNS.png")
    }
    If (!(Test-Path ($env:temp + "\Other.png")))
    {
    (([System.IconExtractor]::Extract("mmcndmgr.dll", 126, $true)).ToBitMap()).Save($env:temp + "\Other.png")
    }


    }

$bolRoot = $null
Remove-Variable -Name "bolRoot" -Scope Global
$ForestRootDomainDN = $null
Remove-Variable -Name "ForestRootDomainDN" -Scope Global
})

$btnScan.add_Click(
{
if ($rdbSACL.IsChecked -eq $true)
{
    # Check for AD powershell module
    if ($(Get-Module -name ActiveDirectory -ListAvailable) -eq $null)
    {
        $global:observableCollection.Insert(0,(LogMessage -strMessage "ActiveDirectory not installed! Scanning SACL's requires the ActiveDirectory Powershell module to be available" -strType "Error" -DateStamp ))
    }
    else
    {
        if ($(Get-Module -name ActiveDirectory) -eq $null)
        {
            #Load ActiveDirectory Module
            Import-Module -Name ActiveDirectory
            $global:observableCollection.Insert(0,(LogMessage -strMessage "ActiveDirectory Powershell module imported" -strType "Warning" -DateStamp ))
        }


        If($chkBoxCompare.IsChecked)
        {
            RunCompare
        }
        else
        {
            RunScan
        }
    }

}
else
{
    If($chkBoxCompare.IsChecked)
    {
        RunCompare
    }
    else
    {
        RunScan
    }
}


})

$btnCreateHTML.add_Click(
{
 if ($txtCSVImport.Text -eq "")
    {
    	$global:observableCollection.Insert(0,(LogMessage -strMessage "No Template CSV file selected!" -strType "Error" -DateStamp ))
    }
    else
    {
        if ($global:bolConnected -eq $true)
        {
            ConvertCSVtoHTM $txtCSVImport.Text $chkBoxTranslateGUIDinCSV.isChecked
        }
        else
        {
        $global:observableCollection.Insert(0,(LogMessage -strMessage "You need to connect to a directory first!" -strType "Error" -DateStamp ))
        }
    }

})



$btnExit.add_Click(
{
#TODO: Place custom script here

#$ErrorActionPreference = "SilentlyContinue"
$bolConnected= $null
$bolTempValue_InhertiedChkBox= $null
$dicDCSpecialSids= $null
$dicNameToSchemaIDGUIDs= $null
$dicRightsGuids= $null
$dicSchemaIDGUIDs= $null
$dicSidToName= $null
$dicSpecialIdentities= $null
$dicWellKnownSids= $null
$intColCount= $null
$intDiffCol= $null
$intWizState= $null
$myPID= $null
$observableCollection= $null
$prevNodeText= $null
$scopeLevel= $null
$strDomainPrinDNName= $null
$strDommainSelect= $null
$strEffectiveRightAccount= $null
$strEffectiveRightSP= $null
$strPinDomDC= $null
$strPrincipalDN= $null
$strPrinDomAttr= $null
$strPrinDomDir= $null
$strPrinDomFlat= $null
$strSPNobjectClass= $null
$tokens= $null
$strDC = $null
$strDomainDNName = $null
$strDomainLongName = $null
$strDomainShortName = $null
$strOwner = $null
remove-variable -name "bolConnected" -Scope Global
remove-variable -name "bolTempValue_InhertiedChkBox" -Scope Global
remove-variable -name "dicDCSpecialSids" -Scope Global
remove-variable -name "dicNameToSchemaIDGUIDs" -Scope Global
remove-variable -name "dicRightsGuids" -Scope Global
remove-variable -name "dicSchemaIDGUIDs" -Scope Global
remove-variable -name "dicSidToName" -Scope Global
remove-variable -name "dicSpecialIdentities" -Scope Global
remove-variable -name "dicWellKnownSids" -Scope Global
remove-variable -name "intColCount" -Scope Global
remove-variable -name "intDiffCol" -Scope Global
remove-variable -name "intWizState" -Scope Global
remove-variable -name "myPID" -Scope Global
remove-variable -name "observableCollection" -Scope Global
remove-variable -name "prevNodeText" -Scope Global
remove-variable -name "scopeLevel" -Scope Global
remove-variable -name "strDomainPrinDNName" -Scope Global
remove-variable -name "strDommainSelect" -Scope Global
remove-variable -name "strEffectiveRightAccount" -Scope Global
remove-variable -name "strEffectiveRightSP" -Scope Global
remove-variable -name "strPinDomDC" -Scope Global
remove-variable -name "strPrincipalDN" -Scope Global
remove-variable -name "strPrinDomAttr" -Scope Global
remove-variable -name "strPrinDomDir" -Scope Global
remove-variable -name "strPrinDomFlat" -Scope Global
remove-variable -name "strSPNobjectClass" -Scope Global
remove-variable -name "tokens" -Scope Global


$ErrorActionPreference = "SilentlyContinue"
    &{#Try
        $xmlDoc = $null
        remove-variable -name "xmlDoc" -Scope Global
    }
    Trap [SystemException]
    {

     SilentlyContinue
    }

$ErrorActionPreference = "Continue"

$ADACLGui.Window.close()

})


$btnGetObjFullFilter.add_Click(
{
    if ($global:bolConnected -eq $true)
    {
        GetSchemaObjectGUID  -Domain $global:strDomainDNName
        $global:observableCollection.Insert(0,(LogMessage -strMessage "All schema objects and attributes listed!" -strType "Info" -DateStamp ))
    }
    else
    {
    $global:observableCollection.Insert(0,(LogMessage -strMessage "Connect to your naming context first!" -strType "Error" -DateStamp ))
    }
})



foreach ($ldapDisplayName in $global:dicSchemaIDGUIDs.values)
{


   [void]$combObjectFilter.Items.Add($ldapDisplayName)
}

$OnLoadForm_StateCorrection=
{#Correct the initial state of the form to prevent the .Net maximized form issue
	$ADACLGui.Window.WindowState = $InitialFormWindowState
}




$treeView1.add_SelectedItemChanged({

$txtBoxSelected.Text = (Get-XMLPath -xmlElement ($this.SelectedItem))

if ($this.SelectedItem.Tag -eq "NotEnumerated")
{

    $xmlNode = $global:xmlDoc

    $NodeDNPath = $($this.SelectedItem.ParentNode.Text.toString())
    [void]$this.SelectedItem.ParentNode.removeChild($this.SelectedItem);
    $Mynodes = $xmlNode.SelectNodes("//OU[@Text='$NodeDNPath']")

    $treeNodePath = $NodeDNPath.Replace("/", "\/")

    # Initialize and Build Domain OU Tree
    $strADDN = [ADSI]"LDAP://$global:strDC/$treeNodePath"
    ProcessOUTree -node $($Mynodes) -ADSObject $strADDN #-nodeCount 0
    # Set tag to show this node is already enumerated
    $this.SelectedItem.Tag  = "Enumerated"

}

})



<######################################################################

    Functions to Build Domains OU Tree XML Document

######################################################################>
#region
function RunCompare
{
If ($txtBoxSelected.Text)
{
    $allSubOU = New-Object System.Collections.ArrayList
    $allSubOU.Clear()
    if ($txtCompareTemplate.Text -eq "")
    {
    	$global:observableCollection.Insert(0,(LogMessage -strMessage "No Template CSV file selected!" -strType "Error" -DateStamp ))
    }
    else
    {
            if ($(Test-Path $txtCompareTemplate.Text) -eq $true)
            {
            if (($chkBoxEffectiveRights.isChecked -eq $true) -or ($chkBoxFilter.isChecked -eq $true))
            {
                if ($chkBoxEffectiveRights.isChecked)
                {
    	            $global:observableCollection.Insert(0,(LogMessage -strMessage "Can't compare while Effective Rights enabled!" -strType "Error" -DateStamp ))
                }
                if ($chkBoxFilter.isChecked)
                {
    	            $global:observableCollection.Insert(0,(LogMessage -strMessage "Can't compare while Filter  enabled!" -strType "Error" -DateStamp ))
                }
            }
            else
            {
               $strCompareFile = $txtCompareTemplate.Text
               ImportADSettings $strCompareFile
	           $global:observableCollection.Insert(0,(LogMessage -strMessage "Scanning..." -strType "Info" -DateStamp ))
	           $BolSkipDefPerm = $chkBoxDefaultPerm.IsChecked
	           $sADobjectName = "LDAP://$global:strDC/" + $txtBoxSelected.Text.ToString()
	           $ADobject =  [ADSI] $sADobjectName
	           $strNode = fixfilename $ADobject.Name
	           $strFileHTA = $env:temp + "\ACLHTML.hta"
	           $strFileHTM = $env:temp + "\"+"$global:strDomainShortName-$strNode"+".htm"
	           CreateHTM "$global:strDomainShortName-$strNode" $strFileHTM
               CreateHTA "$global:strDomainShortName-$strNode" $strFileHTA $strFileHTM $CurrentFSPath


	           InitiateHTM $strFileHTA $chkBoxReplMeta.IsChecked $chkBoxACLsize.IsChecked $chkBoxGetOUProtected.IsChecked $chkBoxEffectiveRightsColor.IsChecked $true
	           InitiateHTM $strFileHTM $chkBoxReplMeta.IsChecked $chkBoxACLsize.IsChecked $chkBoxGetOUProtected.IsChecked $chkBoxEffectiveRightsColor.IsChecked $true
			   $bolTranslateGUIDStoObject = $false
	           If ($txtBoxSelected.Text.ToString().Length -gt 0) {
                    If ($rdbBase.IsChecked -eq $False)
		            {

                        If ($rdbSubtree.IsChecked -eq $true)
		                {
                            if ($chkBoxTemplateNodes.IsChecked -eq $false)
                            {
			                    $allSubOU = GetAllChildNodes $txtBoxSelected.Text $true
                            }
                            Get-PermCompare $allSubOU $BolSkipDefPerm $chkBoxReplMeta.IsChecked $chkBoxGetOwner.IsChecked $chkBoxGetOUProtected.IsChecked $chkBoxACLsize.IsChecked $bolTranslateGUIDStoObject
                        }
                        else
                        {
			                if ($chkBoxTemplateNodes.IsChecked -eq $false)
                            {
                            $allSubOU = GetAllChildNodes $txtBoxSelected.Text $false
                            }
                            Get-PermCompare $allSubOU $BolSkipDefPerm $chkBoxReplMeta.IsChecked $chkBoxGetOwner.IsChecked $chkBoxGetOUProtected.IsChecked $chkBoxACLsize.IsChecked $bolTranslateGUIDStoObject
                        }
                    }
		          else
		          {
                    if ($chkBoxTemplateNodes.IsChecked -eq $false)
                    {
			            $allSubOU = @($txtBoxSelected.Text)
                    }
                    Get-PermCompare $allSubOU $BolSkipDefPerm $chkBoxReplMeta.IsChecked $chkBoxGetOwner.IsChecked $chkBoxGetOUProtected.IsChecked $chkBoxACLsize.IsChecked $bolTranslateGUIDStoObject
		          }# End If
		          $global:observableCollection.Insert(0,(LogMessage -strMessage "Finished" -strType "Info" -DateStamp ))
	           }# End If

           }#End If

        }#End If Test-Path
        else
        {
            $global:observableCollection.Insert(0,(LogMessage -strMessage "CSV file not found!" -strType "Error" -DateStamp ))
        }#End If Test-Path Else
    }# End If
}
else
{
        $global:observableCollection.Insert(0,(LogMessage -strMessage "No object selected!" -strType "Error" -DateStamp ))
}
$allSubOU = ""
$strFileCSV = ""
$strFileHTA = ""
$strFileHTM = ""
$sADobjectName = ""
$date= ""
}
function RunScan
{

$bolPreChecks = $true
If ($txtBoxSelected.Text)
{
    If(($chkBoxFilter.IsChecked -eq $true) -and  (($chkBoxType.IsChecked -eq $false) -and ($chkBoxObject.IsChecked -eq $false) -and ($chkBoxTrustee.IsChecked -eq  $false)))
    {

                   $global:observableCollection.Insert(0,(LogMessage -strMessage "Filter Enabled , but no filter is specified!" -strType "Error" -DateStamp ))
                   $bolPreChecks = $false
    }
    else
    {
        If(($chkBoxFilter.IsChecked -eq $true) -and  (($combAccessCtrl.SelectedIndex -eq -1) -and ($combObjectFilter.SelectedIndex -eq -1) -and ($txtFilterTrustee.Text -eq  "")))
        {

                       $global:observableCollection.Insert(0,(LogMessage -strMessage "Filter Enabled , but no filter is specified!" -strType "Error" -DateStamp ))
                       $bolPreChecks = $false
        }
    }

        If(($chkBoxEffectiveRights.IsChecked -eq $true) -and  ($global:tokens.count -eq 0))
    {
                    $global:observableCollection.Insert(0,(LogMessage -strMessage "Effective rights enabled , but no service principal selected!" -strType "Error" -DateStamp ))
                    $bolPreChecks = $false
    }
    if ($bolPreChecks -eq $true)
    {
        $allSubOU = New-Object System.Collections.ArrayList
        $allSubOU.Clear()
        $global:observableCollection.Insert(0,(LogMessage -strMessage "Scanning..." -strType "Info" -DateStamp ))
	    $BolSkipDefPerm = $chkBoxDefaultPerm.IsChecked
	    $bolCSV = $rdbHTAandCSV.IsChecked

	    $sADobjectName = "LDAP://$global:strDC/" + $txtBoxSelected.Text.ToString().Replace("/", "\/")
	    $ADobject =  [ADSI] $sADobjectName
	    $strNode = $ADobject.name
        $bolTranslateGUIDStoObject = $false
        $date= get-date -uformat %Y%m%d_%H%M%S
        $strNode = fixfilename $strNode
	    $strFileCSV = $txtTempFolder.Text + "\" +$strNode + "_" + $global:strDomainShortName + "_adAclOutput" + $date + ".csv"
	    $strFileHTA = $env:temp + "\ACLHTML.hta"
	    $strFileHTM = $env:temp + "\"+"$global:strDomainShortName-$strNode"+".htm"
        if(!($rdbOnlyCSV.IsChecked))
        {
            if ($chkBoxFilter.IsChecked)
            {
		        CreateHTA "$global:strDomainShortName-$strNode Filtered" $strFileHTA  $strFileHTM $CurrentFSPath
		        CreateHTM "$global:strDomainShortName-$strNode Filtered" $strFileHTM
            }
            else
            {
                CreateHTA "$global:strDomainShortName-$strNode" $strFileHTA $strFileHTM $CurrentFSPath
		        CreateHTM "$global:strDomainShortName-$strNode" $strFileHTM
            }

	        InitiateHTM $strFileHTA $chkBoxReplMeta.IsChecked $chkBoxACLsize.IsChecked $chkBoxGetOUProtected.IsChecked $chkBoxEffectiveRightsColor.IsChecked $false
	        InitiateHTM $strFileHTM $chkBoxReplMeta.IsChecked $chkBoxACLsize.IsChecked $chkBoxGetOUProtected.IsChecked $chkBoxEffectiveRightsColor.IsChecked $false
        }
	    If ($txtBoxSelected.Text.ToString().Length -gt 0)
        {
		    If ($rdbBase.IsChecked -eq $False)
		    {
                If ($rdbSubtree.IsChecked -eq $true)
		        {
			        $allSubOU = GetAllChildNodes $txtBoxSelected.Text $true
                    Get-Perm $allSubOU $global:strDomainShortName $BolSkipDefPerm $chkBoxFilter.IsChecked $chkBoxGetOwner.IsChecked $rdbOnlyCSV.IsChecked $chkBoxReplMeta.IsChecked $chkBoxACLsize.IsChecked $chkBoxEffectiveRights.IsChecked $chkBoxGetOUProtected.IsChecked $bolTranslateGUIDStoObject
                }
                else
                {

                    $allSubOU = GetAllChildNodes $txtBoxSelected.Text $false
                    Get-Perm $allSubOU $global:strDomainShortName $BolSkipDefPerm $chkBoxFilter.IsChecked $chkBoxGetOwner.IsChecked $rdbOnlyCSV.IsChecked $chkBoxReplMeta.IsChecked $chkBoxACLsize.IsChecked $chkBoxEffectiveRights.IsChecked $chkBoxGetOUProtected.IsChecked $bolTranslateGUIDStoObject
                }
            }
		    else
		    {
			    $allSubOU = @($txtBoxSelected.Text)
                Get-Perm $allSubOU $global:strDomainShortName $BolSkipDefPerm $chkBoxFilter.IsChecked $chkBoxGetOwner.IsChecked $rdbOnlyCSV.IsChecked $chkBoxReplMeta.IsChecked $chkBoxACLsize.IsChecked $chkBoxEffectiveRights.IsChecked $chkBoxGetOUProtected.IsChecked $bolTranslateGUIDStoObject
		    }
		    $global:observableCollection.Insert(0,(LogMessage -strMessage "Finished" -strType "Info" -DateStamp ))
	    }
    }
}
else
{
        $global:observableCollection.Insert(0,(LogMessage -strMessage "No object selected!" -strType "Error" -DateStamp ))
}
$allSubOU = ""
$strFileCSV = ""
$strFileHTA = ""
$strFileHTM = ""
$sADobjectName = ""
$date= ""

}
function Get-XMLPath($xmlElement)
{
    $Path = ""
    $Level = 0

    $FQDN = $xmlElement.Text

    return $FQDN
}

function AddXMLAttribute([ref]$node, $szName, $value)
{
	$attribute = $global:xmlDoc.createAttribute($szName);
	[void]$node.value.setAttributeNode($attribute);
	$node.value.setAttribute($szName, $value);
	#return $node;
}



#  Processes an OU tree

function ProcessOUTree($node, $ADSObject)
{



	# Increment the node count to indicate we are done with the domain level
	#$global:ProcessNodeCount++

	$strFilterOUCont = "(&(|(objectClass=organizationalUnit)(objectClass=container)))"
	$strFilterAll = "(&(name=*))"

    $sADobjectName = "LDAP://$global:strDC/" + $($ADSObject.Properties["distinguishedName"]).ToString().Replace("/", "\/")

    # Single line Directory searcher
    $dirSearch = [ADSISEARCHER][ADSI]$sADobjectName
    # set a filter

	If ($rdbBrowseAll.IsChecked -eq $true)
	{
	$dirSearch.Filter = $strFilterAll

	}
	else
	{
 	$dirSearch.Filter = $strFilterOUCont
	}
    # set search scope
    $dirSearch.SearchScope = "OneLevel"
    # set pagesize
    $dirSearch.PageSize = 1000
    $dirSearch.SizeLimit = 999
    $dirSearch.PropertiesToLoad.addrange(('cn','distinguishedName'))
    # execute query
    $results  = $dirSearch.FindAll()
	# Now walk the list and recursively process each child

    for ($iResults = 0; $iResults -lt $results.Count; $iResults++)
    {

		$ADSObject = [ADSI]$results[$iResults].Path

        if ($ADSObject.Properties -ne $null)
        {
		    $NewOUNode = $global:xmlDoc.createElement("OU");

            # Add an Attribute for the Name

            if ("$($ADSObject.properties["Name"])" -ne $null)
		    {

                # Add an Attribute for the Name
                $OUName = "$($ADSObject.properties["Name"])"

                AddXMLAttribute -node ([ref]$NewOUNode) -szName "Name" -value $OUName
                $DNName = "$($ADSObject.properties["distinguishedName"])"
                    AddXMLAttribute -node ([ref]$NewOUNode) -szName "Text" -value $DNName
                     Switch ($($ADSObject.psbase.Properties.Item("objectClass"))[$($ADSObject.psbase.Properties.Item("objectClass")).count-1])
                    {
                    "domainDNS"
                    {
                    AddXMLAttribute -node ([ref]$NewOUNode) -szName "Img" -value "$env:temp\DomainDNS.png"
                    }
                    "OrganizationalUnit"
                    {
                    AddXMLAttribute -node ([ref]$NewOUNode) -szName "Img" -value "$env:temp\OU.png"
                    }
                    "user"
                    {
                     AddXMLAttribute -node ([ref]$NewOUNode) -szName "Img" -value "$env:temp\User.png"
                    }
                    "group"
                    {
                    AddXMLAttribute -node ([ref]$NewOUNode) -szName "Img" -value "$env:temp\Group.png"
                    }
                    "computer"
                    {
                    AddXMLAttribute -node ([ref]$NewOUNode) -szName "Img" -value "$env:temp\Computer.png"
                    }
                    "container"
                    {
                    AddXMLAttribute -node ([ref]$NewOUNode) -szName "Img" -value "$env:temp\Container.png"
                    }
                    default
                    {
                    AddXMLAttribute -node ([ref]$NewOUNode) -szName "Img" -value "$env:temp\Other.png"
                    }
                }
                AddXMLAttribute -node ([ref]$NewOUNode) -szName "Tag" -value "Enumerated"

		        $child = $node.appendChild($NewOUNode);

                ProcessOUTreeStep2OnlyShow -node $NewOUNode -DNName $DNName
            }
        }

      }
$iResults = $null
Remove-Variable -Name "iResults"

}
function ProcessOUTreeStep2OnlyShow($node, $DNName)
{


	# Increment the node count to indicate we are done with the domain level

    $strFilterOUCont = "(&(|(objectClass=organizationalUnit)(objectClass=container)))"
	$strFilterAll = "(&(name=*))"

    $sADobjectName = "LDAP://$global:strDC/" + $DNName.Replace("/", "\/")

    # Single line Directory searcher
    $dirSearch = [ADSISEARCHER][ADSI]$sADobjectName
    # set a filter

	If ($rdbBrowseAll.IsChecked -eq $true)
	{
	$dirSearch.Filter = $strFilterAll

	}
	else
	{
 	$dirSearch.Filter = $strFilterOUCont
	}

    # set search scope
    $dirSearch.SearchScope = "oneLevel"

    # set SizeLimit
    $dirSearch.SizeLimit = 2
    $dirSearch.PropertiesToLoad.addrange(('cn','distinguishedName'))
    # execute query
    $results  = $dirSearch.FindOne()
	# Now walk the list and recursively process each child


    if ($results)
    {

		$ADSObject = [ADSI]$results.Path

        if ($ADSObject.Properties -ne $null)
        {


            # Add an Attribute for the Name
            $NewOUNode = $global:xmlDoc.createElement("OU");
            # Add an Attribute for the Name

            AddXMLAttribute -node ([ref]$NewOUNode) -szName "Name" -value "Click ..."

            AddXMLAttribute -node ([ref]$NewOUNode) -szName "Text" -value "Click ..."
            AddXMLAttribute -node ([ref]$NewOUNode) -szName "Img" -value "$env:temp\Expand.png"
            AddXMLAttribute -node ([ref]$NewOUNode) -szName "Tag" -value "NotEnumerated"

		    [void]$node.appendChild($NewOUNode);

        }
        else
        {

            $global:observableCollection.Insert(0,(LogMessage -strMessage "At least one child object could not be accessed: $DNName" -strType "Warning" -DateStamp ))
            # Add an Attribute for the Name
            $NewOUNode = $global:xmlDoc.createElement("OU");
            # Add an Attribute for the Name

            AddXMLAttribute -node ([ref]$NewOUNode) -szName "Name" -value "Click ..."

            AddXMLAttribute -node ([ref]$NewOUNode) -szName "Text" -value "Click ..."
            AddXMLAttribute -node ([ref]$NewOUNode) -szName "Img" -value "$env:temp\Expand.png"
            AddXMLAttribute -node ([ref]$NewOUNode) -szName "Tag" -value "NotEnumerated"

		    [void]$node.appendChild($NewOUNode);
        }

	}


}
function Get-XMLDomainOUTree
{

    param
    (
        $szDomainRoot
    )



    $treeNodePath = $szDomainRoot.Replace("/", "\/")


    # Initialize and Build Domain OU Tree
    $DomainRoot = [ADSI]"LDAP://$global:strDC/$treeNodePath"

    $DNName = "$($DomainRoot.properties["distinguishedName"])"

    $global:xmlDoc = New-Object -TypeName System.Xml.XmlDocument
    $global:xmlDoc.PreserveWhitespace = $false

    $RootNode = $global:xmlDoc.createElement("DomainRoot")
    AddXMLAttribute -Node ([ref]$RootNode) -szName "Name" -value $szDomainRoot
    AddXMLAttribute -node ([ref]$RootNode) -szName "Text" -value $DNName
     Switch ($($DomainRoot.psbase.Properties.Item("objectClass"))[$($DomainRoot.psbase.Properties.Item("objectClass")).count-1])
                {
                "domainDNS"
                {
                AddXMLAttribute -node ([ref]$RootNode) -szName "Img" -value "$env:temp\DomainDNS.png"
                }
                "OrganizationalUnit"
                {
                AddXMLAttribute -node ([ref]$RootNode) -szName "Img" -value "$env:temp\OU.png"
                }
                "user"
                {
                 AddXMLAttribute -node ([ref]$RootNode) -szName "Img" -value "$env:temp\User.png"
                }
                "group"
                {
                AddXMLAttribute -node ([ref]$RootNode) -szName "Img" -value "$env:temp\Group.png"
                }
                "computer"
                {
                AddXMLAttribute -node ([ref]$RootNode) -szName "Img" -value "$env:temp\Computer.png"
                }
                "container"
                {
                AddXMLAttribute -node ([ref]$RootNode) -szName "Img" -value "$env:temp\Container.png"
                }
                default
                {
                AddXMLAttribute -node ([ref]$RootNode) -szName "Img" -value "$env:temp\Other.png"
                }
            }
    [void]$global:xmlDoc.appendChild($RootNode)

    $node = $global:xmlDoc.documentElement;

    #Process the OU tree
    ProcessOUTree -node $node -ADSObject $DomainRoot #-nodeCount 0

    return $global:xmlDoc
}







$global:dicRightsGuids = @{"Seed" = "xxx"}
$global:dicSidToName = @{"Seed" = "xxx"}
$global:dicDCSpecialSids =@{"BUILTIN\Incoming Forest Trust Builders"="S-1-5-32-557";`
"BUILTIN\Account Operators"="S-1-5-32-548";`
"BUILTIN\Server Operators"="S-1-5-32-549";`
"BUILTIN\Pre-Windows 2000 Compatible Access"="S-1-5-32-554";`
"BUILTIN\Terminal Server License Servers"="S-1-5-32-561";`
"BUILTIN\Windows Authorization Access Group"="S-1-5-32-560"}
$global:dicWellKnownSids = @{"S-1-0"="Null Authority";`
"S-1-0-0"="Nobody";`
"S-1-1"="World Authority";`
"S-1-1-0"="Everyone";`
"S-1-2"="Local Authority";`
"S-1-2-0"="Local ";`
"S-1-2-1"="Console Logon ";`
"S-1-3"="Creator Authority";`
"S-1-3-0"="Creator Owner";`
"S-1-3-1"="Creator Group";`
"S-1-3-2"="Creator Owner Server";`
"S-1-3-3"="Creator Group Server";`
"S-1-3-4"="Owner Rights";`
"S-1-4"="Non-unique Authority";`
"S-1-5"="NT Authority";`
"S-1-5-1"="Dialup";`
"S-1-5-2"="Network";`
"S-1-5-3"="Batch";`
"S-1-5-4"="Interactive";`
"S-1-5-6"="Service";`
"S-1-5-7"="Anonymous";`
"S-1-5-8"="Proxy";`
"S-1-5-9"="Enterprise Domain Controllers";`
"S-1-5-10"="Principal Self";`
"S-1-5-11"="Authenticated Users";`
"S-1-5-12"="Restricted Code";`
"S-1-5-13"="Terminal Server Users";`
"S-1-5-14"="Remote Interactive Logon";`
"S-1-5-15"="This Organization";`
"S-1-5-17"="IUSR";`
"S-1-5-18"="Local System";`
"S-1-5-19"="NT Authority";`
"S-1-5-20"="NT Authority";`
"S-1-5-22"="ENTERPRISE READ-ONLY DOMAIN CONTROLLERS BETA";`
"S-1-5-32-544"="Administrators";`
"S-1-5-32-545"="Users";`
"S-1-5-32-546"="Guests";`
"S-1-5-32-547"="Power Users";`
"S-1-5-32-548"="BUILTIN\Account Operators";`
"S-1-5-32-549"="Server Operators";`
"S-1-5-32-550"="Print Operators";`
"S-1-5-32-551"="Backup Operators";`
"S-1-5-32-552"="Replicator";`
"S-1-5-32-554"="BUILTIN\Pre-Windows 2000 Compatible Access";`
"S-1-5-32-555"="BUILTIN\Remote Desktop Users";`
"S-1-5-32-556"="BUILTIN\Network Configuration Operators";`
"S-1-5-32-557"="BUILTIN\Incoming Forest Trust Builders";`
"S-1-5-32-558"="BUILTIN\Performance Monitor Users";`
"S-1-5-32-559"="BUILTIN\Performance Log Users";`
"S-1-5-32-560"="BUILTIN\Windows Authorization Access Group";`
"S-1-5-32-561"="BUILTIN\Terminal Server License Servers";`
"S-1-5-32-562"="BUILTIN\Distributed COM Users";`
"S-1-5-32-568"="BUILTIN\IIS_IUSRS";`
"S-1-5-32-569"="BUILTIN\Cryptographic Operators";`
"S-1-5-32-573"="BUILTIN\Event Log Readers ";`
"S-1-5-32-574"="BUILTIN\Certificate Service DCOM Access";`
"S-1-5-32-575"="BUILTIN\RDS Remote Access Servers";`
"S-1-5-32-576"="BUILTIN\RDS Endpoint Servers";`
"S-1-5-32-577"="BUILTIN\RDS Management Servers";`
"S-1-5-32-578"="BUILTIN\Hyper-V Administrators";`
"S-1-5-32-579"="BUILTIN\Access Control Assistance Operators";`
"S-1-5-32-580"="BUILTIN\Remote Management Users";`
"S-1-5-64-10"="NTLM Authentication";`
"S-1-5-64-14"="SChannel Authentication";`
"S-1-5-64-21"="Digest Authentication";`
"S-1-5-80"="NT Service";`
"S-1-16-0"="Untrusted Mandatory Level";`
"S-1-16-4096"="Low Mandatory Level";`
"S-1-16-8192"="Medium Mandatory Level";`
"S-1-16-8448"="Medium Plus Mandatory Level";`
"S-1-16-12288"="High Mandatory Level";`
"S-1-16-16384"="System Mandatory Level";`
"S-1-16-20480"="Protected Process Mandatory Level";`
"S-1-16-28672"="Secure Process Mandatory Level"}

#==========================================================================
# Function		: LogMessage
# Arguments     : Type of message, message, date stamping
# Returns   	: Custom psObject with two properties, type and message
# Description   : This function creates a custom object that is used as input to an ListBox for logging purposes
#
#==========================================================================
function LogMessage {
     param (
         [Parameter(
             Mandatory = $true
          )][String[]] $strType="Error" ,

        [Parameter(
             Mandatory = $true
          )][String[]]  $strMessage ,

       [Parameter(
             Mandatory = $false
         )][switch]$DateStamp
     )

     process {

                if ($DateStamp)
                {
                    $newMessageObject = New-Object psObject | `
                    Add-Member NoteProperty Type "$strType" -PassThru |`
                    Add-Member NoteProperty Message "[$(get-date)] $strMessage" -PassThru

                     # $newMessageObject = New-Object psObject | Add-Member NoteProperty Type "Error" -PassThru | Add-Member NoteProperty Message "Modify!" -PassThru
                }
                else
                {
                    $newMessageObject = New-Object psObject | `
                    Add-Member NoteProperty Type "$strType" -PassThru |`
                    Add-Member NoteProperty Message "$strMessage" -PassThru
                }


                return $newMessageObject
            }
 }

#==========================================================================
# Function		: ConvertTo-ObjectArrayListFromPsCustomObject
# Arguments     : Defined Object
# Returns   	: Custom Object List
# Description   : Convert a defined object to a custom, this will help you  if you got a read-only object
#
#==========================================================================
function ConvertTo-ObjectArrayListFromPsCustomObject {
     param (
         [Parameter(
             Position = 0,
             Mandatory = $true,
             ValueFromPipeline = $true,
             ValueFromPipelineByPropertyName = $true
         )] $psCustomObject
     );

     process {

        $myCustomArray = New-Object System.Collections.ArrayList

         foreach ($myPsObject in $psCustomObject) {
             $hashTable = @{};
             $myPsObject | Get-Member -MemberType *Property | % {
                 $hashTable.($_.name) = $myPsObject.($_.name);
             }
             $Newobject = new-object psobject -Property  $hashTable
             [void]$myCustomArray.add($Newobject)
         }
         return $myCustomArray
     }
 }

#==========================================================================
# Function		: GenerateTrustedDomainPicker
# Arguments     : -
# Returns   	: Domain DistinguishedName
# Description   : Windows Form List AD Domains in Forest
#==========================================================================
Function GenerateTrustedDomainPicker
{
[xml]$TrustedDomainPickerXAML =@"
<Window x:Class="WpfApplication1.StatusBar"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        x:Name="Window" Title="Locations" WindowStartupLocation = "CenterScreen"
        Width = "400" Height = "200" ShowInTaskbar = "False" ResizeMode="NoResize" WindowStyle="ToolWindow" Opacity="0.9">
    <Window.Background>
        <LinearGradientBrush>
            <LinearGradientBrush.Transform>
                <ScaleTransform x:Name="Scaler" ScaleX="1" ScaleY="1"/>
            </LinearGradientBrush.Transform>
            <GradientStop Color="#CC064A82" Offset="1"/>
            <GradientStop Color="#FF6797BF" Offset="0.7"/>
            <GradientStop Color="#FF6797BF" Offset="0.3"/>
            <GradientStop Color="#FFD4DBE1" Offset="0"/>
        </LinearGradientBrush>
    </Window.Background>
    <Grid>
        <StackPanel Orientation="Vertical">
            <Label x:Name="lblDomainPciker" Content="Select the location you want to search." Margin="10,05,00,00"/>
        <ListBox x:Name="objListBoxDomainList" HorizontalAlignment="Left" Height="78" Margin="10,05,0,0" VerticalAlignment="Top" Width="320"/>
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
            <Button x:Name="btnOK" Content="OK" Margin="00,05,00,00" Width="50" Height="20"/>
            <Button x:Name="btnCancel" Content="Cancel" Margin="10,05,00,00" Width="50" Height="20"/>
        </StackPanel>
        </StackPanel>
    </Grid>
</Window>

"@

$TrustedDomainPickerXAML.Window.RemoveAttribute("x:Class")

$reader=(New-Object System.Xml.XmlNodeReader $TrustedDomainPickerXAML)
$TrustedDomainPickerGui=[Windows.Markup.XamlReader]::Load( $reader )
$btnOK = $TrustedDomainPickerGui.FindName("btnOK")
$btnCancel = $TrustedDomainPickerGui.FindName("btnCancel")
$objListBoxDomainList = $TrustedDomainPickerGui.FindName("objListBoxDomainList")



$btnCancel.add_Click(
{
$TrustedDomainPickerGui.Close()
})

$btnOK.add_Click({
$global:strDomainPrinDNName=$objListBoxDomainList.SelectedItem

if ( $global:strDomainPrinDNName -eq $global:strDomainLongName )
{
    $lblSelectPrincipalDom.Content = $global:strDomainShortName+":"
}
else
{
    $dse = ([adsi]"LDAP://$global:strDC/CN=System,$global:strDomainDNName")


    $searcher = new-object System.DirectoryServices.DirectorySearcher($dse)
    [void]$searcher.PropertiesToLoad.("cn","name","trustParent","nETBIOSName","nCName")
    $searcher.filter = "(&(trustPartner=$global:strDomainPrinDNName))"
    $searcher.PropertiesToLoad.addrange(('cn','distinguishedNme','trustDirection','trustAttributes','flatname'))
    $colResults = $searcher.FindOne()
    $intCounter = 0

   	if($colResults)
  	{
  		$objExtendedRightsObject = $colResults.Properties
        $global:strPrinDomDir = $objExtendedRightsObject.item("trustDirection")
        $global:strPrinDomAttr = "{0:X2}" -f [int]  $objExtendedRightsObject.item("trustAttributes")[0]
        $global:strPrinDomFlat = $objExtendedRightsObject.item("flatname")[0].ToString()
        $lblSelectPrincipalDom.Content = $global:strPrinDomFlat+":"
    }
}
$TrustedDomainPickerGui.Close()
})


$dse = ([adsi]"LDAP://$global:strDC/CN=System,$global:strDomainDNName")


   		$searcher = new-object System.DirectoryServices.DirectorySearcher($dse)
   		[void]$searcher.PropertiesToLoad.("cn","name","trustParent","nETBIOSName","nCName")
   		$searcher.filter = "(&(cn=*)(objectClass=trustedDomain))"
   		$colResults = $searcher.FindAll()
   		$intCounter = 0

   	foreach ($objResult in $colResults)
  	{

  		$objExtendedRightsObject = $objResult.Properties
    if ( $objExtendedRightsObject.item("trustDirection") -gt 1)
    {
        $strNetbios =$($objExtendedRightsObject.item("flatName"))
        $strDN =$($objExtendedRightsObject.item("trustPartner"))
        [void] $objListBoxDomainList.Items.Add($strDN)
    }
}
[void] $objListBoxDomainList.Items.Add($global:strDomainLongName)

$TrustedDomainPickerGui.ShowDialog()

}
#==========================================================================
# Function		: GenerateDomainPicker
# Arguments     : -
# Returns   	: Domain DistinguishedName
# Description   : Windows Form List AD Domains in Forest
#==========================================================================
Function GenerateDomainPicker
{
[xml]$DomainPickerXAML =@"
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        x:Name="Window" Title="Select a domain" WindowStartupLocation = "CenterScreen"
        Width = "400" Height = "200" ShowInTaskbar = "False" ResizeMode="NoResize" WindowStyle="ToolWindow" Opacity="0.9">
    <Window.Background>
        <LinearGradientBrush>
            <LinearGradientBrush.Transform>
                <ScaleTransform x:Name="Scaler" ScaleX="1" ScaleY="1"/>
            </LinearGradientBrush.Transform>
            <GradientStop Color="#CC064A82" Offset="1"/>
            <GradientStop Color="#FF6797BF" Offset="0.7"/>
            <GradientStop Color="#FF6797BF" Offset="0.3"/>
            <GradientStop Color="#FFD4DBE1" Offset="0"/>
        </LinearGradientBrush>
    </Window.Background>
    <Grid>
        <StackPanel Orientation="Vertical">
        <Label x:Name="lblDomainPciker" Content="Please select a domain:" Margin="10,05,00,00"/>
        <ListBox x:Name="objListBoxDomainList" HorizontalAlignment="Left" Height="78" Margin="10,05,0,0" VerticalAlignment="Top" Width="320"/>
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
            <Button x:Name="btnOK" Content="OK" Margin="00,05,00,00" Width="50" Height="20"/>
            <Button x:Name="btnCancel" Content="Cancel" Margin="10,05,00,00" Width="50" Height="20"/>
        </StackPanel>
        </StackPanel>
    </Grid>
</Window>
"@

$DomainPickerXAML.Window.RemoveAttribute("x:Class")

$reader=(New-Object System.Xml.XmlNodeReader $DomainPickerXAML)
$DomainPickerGui=[Windows.Markup.XamlReader]::Load( $reader )
$btnOK = $DomainPickerGui.FindName("btnOK")
$btnCancel = $DomainPickerGui.FindName("btnCancel")
$objListBoxDomainList = $DomainPickerGui.FindName("objListBoxDomainList")

$btnCancel.add_Click(
{
$DomainPickerGui.Close()
})

$btnOK.add_Click(
{
$global:strDommainSelect=$objListBoxDomainList.SelectedItem
$DomainPickerGui.Close()
})

$Config = ([adsi]"LDAP://rootdse").ConfigurationNamingContext
$dse = [adsi]"LDAP://CN=Partitions,$config"

   		$searcher = new-object System.DirectoryServices.DirectorySearcher($dse)
   		[void]$searcher.PropertiesToLoad.("cn","name","trustParent","nETBIOSName","nCName")
   		$searcher.filter = "(&(cn=*))"
   		$colResults = $searcher.FindAll()
   		$intCounter = 0

   	foreach ($objResult in $colResults)
  	{
  		$objExtendedRightsObject = $objResult.Properties
    if ( $objExtendedRightsObject.item("systemflags") -eq 3)
    {
        $strNetbios =$($objExtendedRightsObject.item("nETBIOSName"))
        $strDN =$($objExtendedRightsObject.item("nCName"))
        [void] $objListBoxDomainList.Items.Add($strDN)
    }
}


$DomainPickerGui.ShowDialog()

}
#==========================================================================
# Function		: GetDomainController
# Arguments     : Domain FQDN,bol using creds, PSCredential
# Returns   	: Domain Controller
# Description   : Locate a domain controller in a specified domain
#==========================================================================
Function GetDomainController
{
Param([string] $strDomainFQDN,
[bool] $bolCreds,
[parameter(Mandatory=$false)]
[System.Management.Automation.PSCredential] $Creds)

$strDomainController = ""

if ($bolCreds -eq $true)
{

        $Context = New-Object DirectoryServices.ActiveDirectory.DirectoryContext("Domain",$strDomainFQDN,$Creds.UserName,$Creds.GetNetworkCredential().Password)
        $ojbDomain = [DirectoryServices.ActiveDirectory.Domain]::GetDomain($Context)
        $strDomainController = $($ojbDomain.FindDomainController()).name
}
else
{

        $Context = New-Object DirectoryServices.ActiveDirectory.DirectoryContext("Domain",$strDomainFQDN )
        $ojbDomain = [DirectoryServices.ActiveDirectory.Domain]::GetDomain($Context)
        $strDomainController = $($ojbDomain.FindDomainController()).name
}

return $strDomainController

}

#==========================================================================
# Function		: Get-Forest
# Arguments     : string domain controller,credentials
# Returns   	: Forest
# Description   : Get AD Forest
#==========================================================================
function Get-Forest
{
Param($DomainController,[Management.Automation.PSCredential]$Credential)
	if(!$DomainController)
	{
		[DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
		return
	  }
	if($Creds)
		{
		$Context = new-object DirectoryServices.ActiveDirectory.DirectoryContext("DirectoryServer",$DomainController,$Creds.UserName,$Creds.GetNetworkCredential().Password)
	}
	else
	{
		$Context = New-Object DirectoryServices.ActiveDirectory.DirectoryContext("DirectoryServer",$DomainController)
	}
	$ojbForest =[DirectoryServices.ActiveDirectory.Forest]::GetForest($Context)

    return $ojbForest
}
#==========================================================================
# Function		: TestCreds
# Arguments     : System.Management.Automation.PSCredential
# Returns   	: Boolean
# Description   : Check If username and password is valid
#==========================================================================
Function TestCreds{
Param([System.Management.Automation.PSCredential] $psCred)

[void][reflection.assembly]::LoadWithPartialName("System.DirectoryServices.AccountManagement")

if ($psCred.UserName -match "\\")
{
    If ($psCred.UserName.split("\")[0] -eq "")
    {
        [directoryservices.directoryEntry]$root = (New-Object system.directoryservices.directoryEntry)

        $ctx = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Domain, $root.name)
    }
    else
    {

        $ctx = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Domain, $psCred.UserName.split("\")[0])
    }
    $bolValid = $ctx.ValidateCredentials($psCred.UserName.split("\")[1],$psCred.GetNetworkCredential().Password)
}
else
{
    [directoryservices.directoryEntry]$root = (New-Object system.directoryservices.directoryEntry)

    $ctx = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Domain, $root.name)

    $bolValid = $ctx.ValidateCredentials($psCred.UserName,$psCred.GetNetworkCredential().Password)
}

return $bolValid
}
#==========================================================================
# Function		: GetTokenGroups
# Arguments     : Principal DistinguishedName string
# Returns   	: ArrayList of groups names
# Description   : Group names of all sids in tokenGroups
#==========================================================================
Function GetTokenGroups
{
Param($PrincipalDN,
[bool] $bolCreds,
[parameter(Mandatory=$false)]
[System.Management.Automation.PSCredential] $Creds)


$script:bolErr = $false
$tokenGroups =  New-Object System.Collections.ArrayList

$tokenGroups.Clear()
if ($bolCreds -eq $true)
{

    $objADObject = new-object DirectoryServices.DirectoryEntry("LDAP://$global:strPinDomDC/$PrincipalDN",$Creds.UserName,$Creds.GetNetworkCredential().Password)

}
else
{

$objADObject = new-object DirectoryServices.DirectoryEntry("LDAP://$global:strPinDomDC/$PrincipalDN")

}
    if ( $global:strDomainPrinDNName -eq $global:strDomainDNName )
    {
$objADObject.psbase.RefreshCache("tokenGroups")
$SIDs = $objADObject.psbase.Properties.Item("tokenGroups")
}
else
{
$objADObject.psbase.RefreshCache("tokenGroupsGlobalandUniversal")
$SIDs = $objADObject.psbase.Properties.Item("tokenGroupsGlobalandUniversal")
}
$ownerSIDs = $objADObject.psbase.Properties.Item("objectSID").tostring()
# Populate hash table with security group memberships.


$arrForeignSecGroups = FindForeignSecPrinMemberships $global:strDomainDNName $global:strDC $(GenerateSearchAbleSID $ownerSIDs)

foreach ($ForeignMemb in $arrForeignSecGroups)
{
       if($ForeignMemb -ne $null )
        {
            if($ForeignMemb.tostring().length -gt 0 )
            {
            [void]$tokenGroups.add($ForeignMemb)
            }
        }
}



ForEach ($Value In $SIDs)
{



    $SID = New-Object System.Security.Principal.SecurityIdentifier $Value, 0


    # Translate into "pre-Windows 2000" name.
    &{#Try
        $Script:Group = $SID.Translate([System.Security.Principal.NTAccount])
    }
    Trap [SystemException]
    {
     $script:bolErr = $true
     $script:sidstring = GetSidStringFromSidByte $Value
     continue
    }
    if ($script:bolErr  -eq $false)
     {

    [void]$tokenGroups.Add($Script:Group.Value)
      }
      else
    {

        [void]$tokenGroups.Add($script:sidstring)
        $script:bolErr = $false
    }

    $arrForeignSecGroups = FindForeignSecPrinMemberships $global:strDomainDNName $global:strDC $(GenerateSearchAbleSID $Value)

    foreach ($ForeignMemb in $arrForeignSecGroups)
    {
       if($ForeignMemb -ne $null )
        {
            if($ForeignMemb.tostring().length -gt 0 )
            {
            [void]$tokenGroups.add($ForeignMemb)
            }
        }
    }

}

         [void]$tokenGroups.Add("Everyone")
         [void]$tokenGroups.Add("NT AUTHORITY\Authenticated Users")
if(($global:strPrinDomAttr -eq 14) -or ($global:strPrinDomAttr -eq 18) -or ($global:strPrinDomAttr -eq "5C") -or ($global:strPrinDomAttr -eq "1C") -or ($global:strPrinDomAttr -eq "44")  -or ($global:strPrinDomAttr -eq "54")  -or ($global:strPrinDomAttr -eq "50"))
{
         [void]$tokenGroups.Add("NT AUTHORITY\Other Organization")
}
else
{
         [void]$tokenGroups.Add("NT AUTHORITY\This Organization")
}
Return $tokenGroups

}


#==========================================================================
# Function		: GenerateSearchAbleSID
# Arguments     : SID Decimal form Value as string
# Returns   	: SID in String format for LDAP searcheds
# Description   : Convert SID from decimal to hex with "\" for searching with LDAP
#==========================================================================
Function GenerateSearchAbleSID
{
Param([String] $SidValue)

$SidDec =$SidValue.tostring().split("")
Foreach ($intSID in $SIDDec)
{
[string] $SIDHex = "{0:X2}" -f [int] $intSID
$strSIDHextString = $strSIDHextString + "\" + $SIDHex

}

return $strSIDHextString
}
#==========================================================================
# Function		: FindForeignSecPrinMemberships
# Arguments     : SID Decimal form Value as string
# Returns   	: SID in String format for LDAP searcheds
# Description   : Convert SID from decimal to hex with "\" for searching with LDAP
#==========================================================================
Function FindForeignSecPrinMemberships
{
Param([string] $strLocalDomDN,[string] $strDC,[string] $strSearchAbleSID)

$arrForeignMembership = New-Object System.Collections.ArrayList
[void]$arrForeignMembership.clear()
$domaininfo = new-object DirectoryServices.DirectoryEntry("LDAP://$strDC/CN=ForeignSecurityPrincipals,$strLocalDomDN")

$srch = New-Object System.DirectoryServices.DirectorySearcher($domaininfo)

		$srch.SizeLimit = 100
        $strFilter = "(&(objectSID=$strSearchAbleSID))"
 		$srch.Filter = $strFilter
		$srch.SearchScope = "Subtree"
		$res = $srch.FindOne()
	    if($res)
        {
	        $objPrincipal = $res.GetDirectoryEntry()

            $objPrincipal.psbase.RefreshCache("memberof")
            Foreach ($member in @($objPrincipal.psbase.Properties.Item("memberof")))
            {
                $objmember = new-object DirectoryServices.DirectoryEntry("LDAP://$strDC/$member")

                $objmember.psbase.RefreshCache("msDS-PrincipalName")
                $strPrinName = $($objmember.psbase.Properties.Item("msDS-PrincipalName"))
                if (($strPrinName -eq "") -or ($strPrinName -eq $null))
                {
                $strNETBIOSNAME = $global:strPrinDomFlat
                $strPrinName = "$strNETBIOSNAME\$($objmember.psbase.Properties.Item("samAccountName"))"
                }
                                [void]$arrForeignMembership.add($strPrinName)
            }


	    }
return $arrForeignMembership
}
#==========================================================================
# Function		: GetSidStringFromSidByte
# Arguments     : SID Value in Byte[]
# Returns   	: SID in String format
# Description   : Convert SID from Byte[] to String
#==========================================================================
Function GetSidStringFromSidByte
{
Param([byte[]] $SidByte)

    $objectSid = [byte[]]$SidByte
    $sid = New-Object System.Security.Principal.SecurityIdentifier($objectSid,0)
    $sidString = ($sid.value).ToString()
    return $sidString
}
#==========================================================================
# Function		: GetSecPrinDN
# Arguments     : samAccountName
# Returns   	: DistinguishedName
# Description   : Search Security Principal and Return DistinguishedName
#==========================================================================
Function GetSecPrinDN
{
Param([string] $samAccountName,
[string] $strDomainDN,
[bool] $bolCreds,
[parameter(Mandatory=$false)]
[System.Management.Automation.PSCredential] $Creds)


if ($bolCreds -eq $true)
{


    $domaininfo = new-object DirectoryServices.DirectoryEntry("LDAP://$strDomainDN",$Creds.UserName,$Creds.GetNetworkCredential().Password)

}
else
{

    $domaininfo = new-object DirectoryServices.DirectoryEntry("LDAP://$strDomainDN")
}
$srch = New-Object System.DirectoryServices.DirectorySearcher($domaininfo)

		$srch.SizeLimit = 100
        $strFilter = "(&(samAccountName=$samAccountName))"
 		$srch.Filter = $strFilter
		$srch.SearchScope = "Subtree"
		$res = $srch.FindOne()
	    if($res)
        {
	        $objPrincipal = $res.GetDirectoryEntry()
	        $global:strPrincipalDN = $objPrincipal.distinguishedName
	    }
        else
        {
        $global:strPrincipalDN = ""
        }

return $global:strPrincipalDN

}


#==========================================================================
# Function		: GetSchemaObjectGUID
# Arguments     : Object Guid or Rights Guid
# Returns   	: LDAPDisplayName or DisplayName
# Description   : Searches in the dictionaries(Hash) dicRightsGuids and $global:dicSchemaIDGUIDs  and in Schema
#				for the name of the object or Extended Right, if found in Schema the dicRightsGuids is updated.
#				Then the functions return the name(LDAPDisplayName or DisplayName).
#==========================================================================
Function GetSchemaObjectGUID{
Param([string] $Domain)
	[string] $strOut =""
	[string] $objSchemaRecordset = ""
	[string] $strLDAPname = ""

    [void]$combObjectFilter.Items.Clear()
    BuildSchemaDic
    foreach ($ldapDisplayName in $global:dicSchemaIDGUIDs.values)
    {
        [void]$combObjectFilter.Items.Add($ldapDisplayName)
    }
			 if ($Domain -eq "")
			 {
				# Connect to RootDSE
				$rootDSE = [ADSI]"LDAP://$global:strDC/RootDSE"
				#Connect to the Configuration Naming Context
				$schemaSearchRoot = [ADSI]("LDAP://$global:strDC/" + $rootDSE.Get("schemaNamingContext"))
			 }
			 else
			 {
				$rootDSE = [ADSI]"LDAP://$global:strDC/$Domain"
				$schemaSearchRoot = [ADSI]("LDAP://$global:strDC/" + $rootDSE.Get("objectCategory"))
				$schemaSearchRoot = $schemaSearchRoot.path.replace("LDAP://$global:strDC/CN=Domain-DNS,","")
				$schemaSearchRoot = [ADSI]("LDAP://$global:strDC/" + $schemaSearchRoot)
			 }
			 $searcher = new-object System.DirectoryServices.DirectorySearcher($schemaSearchRoot)
			 $searcher.PropertiesToLoad.addrange(('cn','name','distinguishedNAme','lDAPDisplayName','schemaIDGUID'))
			 $searcher.PageSize = 1000
             $searcher.filter = "(&(schemaIDGUID=*))"
			 $colResults = $searcher.FindAll()
 			 $intCounter = 0


		 	foreach ($objResult in $colResults)
			{
    			$objSchemaObject = $objResult.Properties
				$strLDAPname =$objSchemaObject.item("lDAPDisplayName")[0]
				$guidGUID = [System.GUID]$objSchemaObject.item("schemaIDGUID")[0]
                $strGUID = $guidGUID.toString().toUpper()
				If (!($global:dicSchemaIDGUIDs.ContainsKey($strGUID)))
                {
                    $global:dicSchemaIDGUIDs.Add($strGUID,$strLDAPname)
                    $global:dicNameToSchemaIDGUIDs.Add($strLDAPname,$strGUID)
                    [void]$combObjectFilter.Items.Add($strLDAPname)
                }

			 }

	return $strOut
}

#==========================================================================
# Function		: Get-ADSchemaClass
# Arguments     : string class,string domain controller,credentials
# Returns   	: Class Object
# Description   : Get AD Schema Class
#==========================================================================
function Get-ADSchemaClass
{
Param($Class = ".*")

	$ADSchemaClass = $global:Forest.Schema.FindAllClasses() | ?{$_.Name -match "^$Class`$"}

    return $ADSchemaClass
}



#==========================================================================
# Function		: CheckDNExist
# Arguments     : string distinguishedName
# Returns   	: Boolean
# Description   : Check If distinguishedName exist
#==========================================================================
function CheckDNExist
{
Param (
  $sADobjectName
  )
  $sADobjectName = "LDAP://" + $sADobjectName
    $ADobject =  [ADSI] $sADobjectName
    If($ADobject.distinguishedName -eq $null)
    {return $false}
    else
    {return $true}

}
#==========================================================================
# Function		: ReverseString
# Arguments     : string
# Returns   	: string backwards
# Description   : Turn a string backwards
#==========================================================================
Function ReverseString{

param ($string)
ForEach ($char in $string)
{
    ([regex]::Matches($char,'.','RightToLeft') | ForEach {$_.value}) -join ''
}

}


#==========================================================================
# Function		: GetAllChildNodes
# Arguments     : Node distinguishedName
# Returns   	: List of Nodes
# Description   : Search for a Node and returns distinguishedName
#==========================================================================
function GetAllChildNodes{
param ($firstnode,
[boolean] $bolSubtree)
$nodelist = New-Object System.Collections.ArrayList
$nodelist2 = New-Object System.Collections.ArrayList
$nodelist.Clear()
$nodelist2.Clear()
# Add all Children found as Sub Nodes to the selected TreeNode

$strFilterAll = "(&(objectClass=*))"
$strFilterContainer = "(&(|(objectClass=organizationalUnit)(objectClass=container)(objectClass=DomainDNS)(objectClass=dMD)))"
$strFilterOU = "(&(|(objectClass=organizationalUnit)(objectClass=DomainDNS)(objectClass=dMD)))"
$srch = New-Object System.DirectoryServices.DirectorySearcher

if ($firstnode -match "/")
{
    $firstnode = $firstnode.Replace("/", "\/")
}

$srch.SearchRoot = "LDAP://$firstnode"
If ($rdbScanAll.IsChecked -eq $true)
{
	$srch.Filter = $strFilterAll
}
If ($rdbScanOU.IsChecked -eq $true)
{
	$srch.Filter = $strFilterOU
}
If ($rdbScanContainer.IsChecked -eq $true)
{
	$srch.Filter = $strFilterContainer
}
if ($bolSubtree -eq $true)
{
    $srch.SearchScope = "Subtree"
}
else
{
    $srch.SearchScope = "onelevel"
}
$srch.PageSize = 1000
$srch.PropertiesToLoad.addrange(('cn','distinguishedNAme'))
foreach ($res in $srch.FindAll())
{
    $oNode = $res.GetDirectoryEntry()
    [void] $nodelist.Add($(ReverseString -String $oNode.distinguishedName))
}
if ($bolSubtree -eq $false)
{
    [void] $nodelist.Add($(ReverseString -String $firstnode))
}
foreach ($bkwrNode in $($nodelist | Sort-Object))
{
    [void] $nodelist2.Add($(ReverseString -String $bkwrNode))

}

return $nodelist2

}
#==========================================================================
# Function		: Get-DomainDNfromFQDN
# Arguments     : Domain FQDN
# Returns   	: Domain DN
# Description   : Take domain FQDN as input and returns Domain name
#                  in DN
#==========================================================================
function Get-DomainDNfromFQDN
{
Param($strDomainFQDN)

        $strADObjectDNModified= $strDomainFQDN.tostring().Replace(".",",DC=")

        $strDomDN="DC="+$strADObjectDNModified


    return $strDomDN
}

#==========================================================================
# Function		: Get-DomainDN
# Arguments     : string AD object distinguishedName
# Returns   	: Domain DN
# Description   : Take dinstinguishedName as input and returns Domain name
#                  in DN
#==========================================================================
function Get-DomainDN
{
Param($strADObjectDN)

        $strADObjectDNModified= $strADObjectDN.Replace(",DC=","*")

        [array]$arrDom = $strADObjectDNModified.split("*")
        $intSplit = ($arrDom).count -1
        $strDomDN = ""
        for ($i=$intSplit;$i -ge 1; $i-- )
        {
            if ($i -eq 1)
            {
                $strDomDN="DC="+$arrDom[$i]+$strDomDN
            }
            else
            {
                $strDomDN=",DC="+$arrDom[$i]+$strDomDN
            }
        }
    $i = $null
    Remove-Variable -Name "i"
    return $strDomDN
}

#==========================================================================
# Function		: Get-DomainFQDN
# Arguments     : string AD object distinguishedName
# Returns   	: Domain FQDN
# Description   : Take dinstinguishedName as input and returns Domain name
#                  in FQDN
#==========================================================================
function Get-DomainFQDN
{
Param($strADObjectDN)

        $strADObjectDNModified= $strADObjectDN.Replace(",DC=","*")

        [array]$arrDom = $strADObjectDNModified.split("*")
        $intSplit = ($arrDom).count -1
        $strDomName = ""
        for ($i=$intSplit;$i -ge 1; $i-- )
        {
            if ($i -eq $intSplit)
            {
                $strDomName=$arrDom[$i]+$strDomName
            }
            else
            {
                $strDomName=$arrDom[$i]+"."+$strDomName
            }
        }

    $i = $null
    Remove-Variable -Name "i"

    return $strDomName
}
#==========================================================================
# Function		: GetDomainShortName
# Arguments     : domain name
# Returns   	: N/A
# Description   : Search for short domain name
#==========================================================================
function GetDomainShortName {
Param($strDomain,
[string]$strForestDN)

	$objDomain = [ADSI]"LDAP://$global:strDC/$strDomain"

	$ReturnShortName = ""


	$strRootPath = "LDAP://$global:strDC/CN=Partitions,CN=Configuration,$strForestDN"

	$root = [ADSI]$strRootPath

	$ads = New-Object System.DirectoryServices.DirectorySearcher($root)
    $ads.PropertiesToLoad.addrange(('cn','distinguishedNAme','nETBIOSName'))
	$ads.filter = "(&(objectClass=crossRef)(nCName=$strDomain))"
	$s = $ads.FindOne()
	If ($s)
	{
		$ReturnShortName = $s.GetDirectoryEntry().nETBIOSName
	}
	else
	{
		$ReturnShortName = ""
	}
return $ReturnShortName
}
#==========================================================================
# Function		: GetNCShortName
# Arguments     : AD NamingContext distinguishedName
# Returns   	: N/A
# Description   : Return CN of NC
#==========================================================================
function GetNCShortName {
Param($strNode)
	$objNC = [ADSI]"LDAP://$global:strDC/$strNode"
	Switch -regex ($objNC.objectCategory)
	{
	 "CN=Domain-DNS,CN=Schema,CN=Configuration"
	 {[string]$strNCcn = $objNC.name}
	 "CN=Configuration,CN=Schema,CN=Configuration"
	 {[string]$strNCcn = $objNC.cn}
	 "CN=DMD,CN=Schema,CN=Configuration"
	 {[string]$strNCcn = $objNC.cn}
	}
return $strNCcn
}

#==========================================================================
# Function		: Check-PermDef
# Arguments     : Trustee Name,Right,Allow/Deny,object guid,Inheritance,Inheritance object guid
# Returns   	: Boolean
# Description   : Compares the Security Descriptor with the DefaultSecurity
#==========================================================================
Function Check-PermDef{
Param($objNodeDefSD,
[string]$strTrustee,
[string]$adRights,
[string]$InheritanceType,
[string]$ObjectTypeGUID,
[string]$InheritedObjectTypeGUID,
[string]$ObjectFlags,
[string]$AccessControlType,
[string]$IsInherited,
[string]$InheritedFlags,
[string]$PropFlags)
$SDResult = $false
$Identity = "$strTrustee"
    $sdOUDef =  New-Object System.Collections.ArrayList
    $sdOUDef.clear()
$defSD = $objNodeDefSD | %{$_.DefaultObjectSecurityDescriptor} | %{$objNodeDefSD.DefaultObjectSecurityDescriptor.access}
if($defSD -ne $null){

$(ConvertTo-ObjectArrayListFromPsCustomObject  $defSD)| %{[void]$sdOUDef.add($_)}
$defSD = ""
if ($objNodeDefSD.name -eq "computer")
{

        $additionalComputerACE = New-Object psObject | `
        Add-Member NoteProperty ActiveDirectoryRights "DeleteTree, ExtendedRight, Delete, GenericRead" -PassThru |`
        Add-Member NoteProperty InheritanceType "None" -PassThru |`
        Add-Member NoteProperty ObjectType  "00000000-0000-0000-0000-000000000000" -PassThru |`
        Add-Member NoteProperty InheritedObjectType "00000000-0000-0000-0000-000000000000" -PassThru |`
        Add-Member NoteProperty ObjectFlags "None" -PassThru |`
        Add-Member NoteProperty AccessControlType "Allow" -PassThru |`
        Add-Member NoteProperty IdentityReference $global:strOwner -PassThru |`
        Add-Member NoteProperty IsInherited "False" -PassThru |`
        Add-Member NoteProperty InheritanceFlags "None" -PassThru |`
        Add-Member NoteProperty PropagationFlags "None"  -PassThru

        [void]$sdOUDef.insert(0,$additionalComputerACE)

        $additionalComputerACE = New-Object psObject | `
        Add-Member NoteProperty ActiveDirectoryRights "WriteProperty" -PassThru |`
        Add-Member NoteProperty InheritanceType "None" -PassThru |`
        Add-Member NoteProperty ObjectType  "4c164200-20c0-11d0-a768-00aa006e0529" -PassThru |`
        Add-Member NoteProperty InheritedObjectType "00000000-0000-0000-0000-000000000000" -PassThru |`
        Add-Member NoteProperty ObjectFlags "ObjectAceTypePresent" -PassThru |`
        Add-Member NoteProperty AccessControlType "Allow" -PassThru |`
        Add-Member NoteProperty IdentityReference $global:strOwner -PassThru |`
        Add-Member NoteProperty IsInherited "False" -PassThru |`
        Add-Member NoteProperty InheritanceFlags "None" -PassThru |`
        Add-Member NoteProperty PropagationFlags "None"  -PassThru

        [void]$sdOUDef.insert(0,$additionalComputerACE)

        $additionalComputerACE = New-Object psObject | `
        Add-Member NoteProperty ActiveDirectoryRights "WriteProperty" -PassThru |`
        Add-Member NoteProperty InheritanceType "None" -PassThru |`
        Add-Member NoteProperty ObjectType  "3e0abfd0-126a-11d0-a060-00aa006c33ed" -PassThru |`
        Add-Member NoteProperty InheritedObjectType "00000000-0000-0000-0000-000000000000" -PassThru |`
        Add-Member NoteProperty ObjectFlags "ObjectAceTypePresent" -PassThru |`
        Add-Member NoteProperty AccessControlType "Allow" -PassThru |`
        Add-Member NoteProperty IdentityReference $global:strOwner -PassThru |`
        Add-Member NoteProperty IsInherited "False" -PassThru |`
        Add-Member NoteProperty InheritanceFlags "None" -PassThru |`
        Add-Member NoteProperty PropagationFlags "None"  -PassThru

        [void]$sdOUDef.insert(0,$additionalComputerACE)

        $additionalComputerACE = New-Object psObject | `
        Add-Member NoteProperty ActiveDirectoryRights "WriteProperty" -PassThru |`
        Add-Member NoteProperty InheritanceType "None" -PassThru |`
        Add-Member NoteProperty ObjectType  "bf967953-0de6-11d0-a285-00aa003049e2" -PassThru |`
        Add-Member NoteProperty InheritedObjectType "00000000-0000-0000-0000-000000000000" -PassThru |`
        Add-Member NoteProperty ObjectFlags "ObjectAceTypePresent" -PassThru |`
        Add-Member NoteProperty AccessControlType "Allow" -PassThru |`
        Add-Member NoteProperty IdentityReference $global:strOwner -PassThru |`
        Add-Member NoteProperty IsInherited "False" -PassThru |`
        Add-Member NoteProperty InheritanceFlags "None" -PassThru |`
        Add-Member NoteProperty PropagationFlags "None"  -PassThru

        [void]$sdOUDef.insert(0,$additionalComputerACE)

        $additionalComputerACE = New-Object psObject | `
        Add-Member NoteProperty ActiveDirectoryRights "WriteProperty" -PassThru |`
        Add-Member NoteProperty InheritanceType "None" -PassThru |`
        Add-Member NoteProperty ObjectType  "bf967950-0de6-11d0-a285-00aa003049e2" -PassThru |`
        Add-Member NoteProperty InheritedObjectType "00000000-0000-0000-0000-000000000000" -PassThru |`
        Add-Member NoteProperty ObjectFlags "ObjectAceTypePresent" -PassThru |`
        Add-Member NoteProperty AccessControlType "Allow" -PassThru |`
        Add-Member NoteProperty IdentityReference $global:strOwner -PassThru |`
        Add-Member NoteProperty IsInherited "False" -PassThru |`
        Add-Member NoteProperty InheritanceFlags "None" -PassThru |`
        Add-Member NoteProperty PropagationFlags "None"  -PassThru

        [void]$sdOUDef.insert(0,$additionalComputerACE)

        $additionalComputerACE = New-Object psObject | `
        Add-Member NoteProperty ActiveDirectoryRights "WriteProperty" -PassThru |`
        Add-Member NoteProperty InheritanceType "None" -PassThru |`
        Add-Member NoteProperty ObjectType  "5f202010-79a5-11d0-9020-00c04fc2d4cf" -PassThru |`
        Add-Member NoteProperty InheritedObjectType "00000000-0000-0000-0000-000000000000" -PassThru |`
        Add-Member NoteProperty ObjectFlags "ObjectAceTypePresent" -PassThru |`
        Add-Member NoteProperty AccessControlType "Allow" -PassThru |`
        Add-Member NoteProperty IdentityReference $global:strOwner -PassThru |`
        Add-Member NoteProperty IsInherited "False" -PassThru |`
        Add-Member NoteProperty InheritanceFlags "None" -PassThru |`
        Add-Member NoteProperty PropagationFlags "None"  -PassThru

        [void]$sdOUDef.insert(0,$additionalComputerACE)

        $additionalComputerACE = New-Object psObject | `
        Add-Member NoteProperty ActiveDirectoryRights "Self" -PassThru |`
        Add-Member NoteProperty InheritanceType "None" -PassThru |`
        Add-Member NoteProperty ObjectType  "f3a64788-5306-11d1-a9c5-0000f80367c1" -PassThru |`
        Add-Member NoteProperty InheritedObjectType "00000000-0000-0000-0000-000000000000" -PassThru |`
        Add-Member NoteProperty ObjectFlags "ObjectAceTypePresent" -PassThru |`
        Add-Member NoteProperty AccessControlType "Allow" -PassThru |`
        Add-Member NoteProperty IdentityReference $global:strOwner -PassThru |`
        Add-Member NoteProperty IsInherited "False" -PassThru |`
        Add-Member NoteProperty InheritanceFlags "None" -PassThru |`
        Add-Member NoteProperty PropagationFlags "None"  -PassThru

        [void]$sdOUDef.insert(0,$additionalComputerACE)

        $additionalComputerACE = New-Object psObject | `
        Add-Member NoteProperty ActiveDirectoryRights "Self" -PassThru |`
        Add-Member NoteProperty InheritanceType "None" -PassThru |`
        Add-Member NoteProperty ObjectType  "72e39547-7b18-11d1-adef-00c04fd8d5cd" -PassThru |`
        Add-Member NoteProperty InheritedObjectType "00000000-0000-0000-0000-000000000000" -PassThru |`
        Add-Member NoteProperty ObjectFlags "ObjectAceTypePresent" -PassThru |`
        Add-Member NoteProperty AccessControlType "Allow" -PassThru |`
        Add-Member NoteProperty IdentityReference $global:strOwner -PassThru |`
        Add-Member NoteProperty IsInherited "False" -PassThru |`
        Add-Member NoteProperty InheritanceFlags "None" -PassThru |`
        Add-Member NoteProperty PropagationFlags "None"  -PassThru

        [void]$sdOUDef.insert(0,$additionalComputerACE)
}# End if Computer

$index=0
while($index -le $sdOUDef.count -1) {
			if (($sdOUDef[$index].IdentityReference -eq $strTrustee) -and ($sdOUDef[$index].ActiveDirectoryRights -eq $adRights) -and ($sdOUDef[$index].AccessControlType -eq $AccessControlType) -and ($sdOUDef[$index].ObjectType -eq $ObjectTypeGUID) -and ($sdOUDef[$index].InheritanceType -eq $InheritanceType) -and ($sdOUDef[$index].InheritedObjectType -eq $InheritedObjectTypeGUID))
			{
			$SDResult = $true
			}#} #End If
 $index++
} #End While
}
return $SDResult

}

#==========================================================================
# Function		: CacheRightsGuids
# Arguments     : none
# Returns   	: nothing
# Description   : Enumerates all Extended Rights and put them in a Hash dicRightsGuids
#==========================================================================
Function CacheRightsGuids([string] $Domain)
{
if (!$Domain)
		{
		# Connect to RootDSE
		$rootDSE = [ADSI]"LDAP://RootDSE"
		#Connect to the Configuration Naming Context
		$configSearchRoot = [ADSI]("LDAP://CN=Extended-Rights," + $rootDSE.Get("configurationNamingContext"))
		}
		else
		{
		$rootDSE = [ADSI]"LDAP://$global:strDC/$Domain"
		$configSearchRoot = [ADSI]("LDAP://$global:strDC/" + $rootDSE.Get("objectCategory"))
		$configSearchRoot = $configSearchRoot.psbase.path.replace("LDAP://CN=Domain-DNS,CN=Schema,","")

        $configSearchRoot = [ADSI]("LDAP://$global:strDC/CN=Extended-Rights,CN=Configuration," + $global:ForestRootDomainDN)
		}

		$searcher = new-object System.DirectoryServices.DirectorySearcher($configSearchRoot)
		$searcher.PropertiesToLoad.("cn","name","distinguishedNAme","rightsGuid")
		$searcher.filter = "(&(objectClass=controlAccessRight))"
		$colResults = $searcher.FindAll()
 		$intCounter = 0


	foreach ($objResult in $colResults)
	{
		$objExtendedRightsObject = $objResult.Properties
		If (($objExtendedRightsObject.item("validAccesses") -eq 48) -or ($objExtendedRightsObject.item("validAccesses") -eq 256))
		{

		$strRightDisplayName = $objExtendedRightsObject.item("displayName")
		$strRightGuid = $objExtendedRightsObject.item("rightsGuid")
		$strRightGuid = $($strRightGuid).toString()
		$global:dicRightsGuids.Add($strRightGuid,$strRightDisplayName)

		}
		$intCounter++
		}


}
#==========================================================================
# Function		: MapGUIDToMatchingName
# Arguments     : Object Guid or Rights Guid
# Returns   	: LDAPDisplayName or DisplayName
# Description   : Searches in the dictionaries(Hash) dicRightsGuids and $global:dicSchemaIDGUIDs  and in Schema
#				for the name of the object or Extended Right, if found in Schema the dicRightsGuids is updated.
#				Then the functions return the name(LDAPDisplayName or DisplayName).
#==========================================================================
Function MapGUIDToMatchingName{
Param([string] $strGUIDAsString,[string] $Domain)
	[string] $strOut =""
	[string] $objSchemaRecordset = ""
	[string] $strLDAPname = ""

	If ($strGUIDAsString -eq "")
	{

	 Break
	 }
	$strGUIDAsString = $strGUIDAsString.toUpper()
	$strOut =""
	if ($global:dicRightsGuids.ContainsKey($strGUIDAsString))
	{
		$strOut =$global:dicRightsGuids.Item($strGUIDAsString)
	}

	If ($strOut -eq "")
	{  #Didn't find a match in extended rights
		If ($global:dicSchemaIDGUIDs.ContainsKey($strGUIDAsString))
		{
			$strOut =$global:dicSchemaIDGUIDs.Item($strGUIDAsString)
		}
		else
		{

		 if ($strGUIDAsString -match("^(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}$"))
		 {

			 $ConvertGUID = ConvertGUID($strGUIDAsString)
			 if (!($Domain -eq ""))
			 {
				# Connect to RootDSE
				$rootDSE = [ADSI]"LDAP://RootDSE"
				#Connect to the Configuration Naming Context
				$schemaSearchRoot = [ADSI]("LDAP://" + $rootDSE.Get("schemaNamingContext"))
			 }
			 else
			 {
				$rootDSE = [ADSI]"LDAP://$global:strDC/$Domain"
				$schemaSearchRoot = [ADSI]("LDAP://$global:strDC/" + $rootDSE.Get("objectCategory"))
				$schemaSearchRoot = $schemaSearchRoot.path.replace("LDAP://CN=Domain-DNS,","")
				$schemaSearchRoot = [ADSI]("LDAP://$global:strDC/" + $schemaSearchRoot)
			 }
			 $searcher = new-object System.DirectoryServices.DirectorySearcher($schemaSearchRoot)
			 $searcher.PropertiesToLoad.addrange(('cn','name','distinguishedNAme','lDAPDisplayName'))
			 $searcher.filter = "(&(schemaIDGUID=$ConvertGUID))"
			 $Object = $searcher.FindOne()
			 if ($Object)
			 {
				$objSchemaObject = $Object.Properties
				$strLDAPname =$objSchemaObject.item("lDAPDisplayName")[0]
				$global:dicSchemaIDGUIDs.Add($strGUIDAsString.toUpper(),$strLDAPname)
				$strOut=$strLDAPname

			 }
		}
	  }
	}

	return $strOut
}
#==========================================================================
# Function		: ConvertGUID
# Arguments     : Object Guid or Rights Guid
# Returns   	: AD Searchable GUID String
# Description   : Convert a GUID to a string

#==========================================================================
 function ConvertGUID($guid)
 {

	 $test = "(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})"
	 $pattern = '"\$4\$3\$2\$1\$6\$5\$8\$7\$9\$10\$11\$12\$13\$14\$15\$16"'
	 $ConvertGUID = [regex]::Replace($guid.replace("-",""), $test, $pattern).Replace("`"","")
	 return $ConvertGUID
}
#==========================================================================
# Function		: fixfilename
# Arguments     : Text for naming text file
# Returns   	: Text with replace special characters
# Description   : Replace characters that be contained in a file name.

#==========================================================================
function fixfilename([string] $strFileName)
{

    $strFileName = $strFileName.Replace("*","#")
    $strFileName = $strFileName.Replace("/","#")
    $strFileName = $strFileName.Replace("\","#")
    $strFileName = $strFileName.Replace(":","#")
    $strFileName = $strFileName.Replace("<","#")
    $strFileName = $strFileName.Replace(">","#")
    $strFileName = $strFileName.Replace("|","#")
    $strFileName = $strFileName.Replace('"',"#")
    $strFileName = $strFileName.Replace('?',"#")

    return $strFileName
}
#==========================================================================
# Function		: WritePermCSV
# Arguments     : Security Descriptor, OU distinguishedName, Ou put text file
# Returns   	: n/a
# Description   : Writes the SD to a text file.
#==========================================================================
function WritePermCSV($sd,[string]$ou,[string] $fileout, [bool] $ACLMeta,[string]  $strACLDate,[string] $strInvocationID,[string] $strOrgUSN)
{

	$sd  | foreach {
	If ($global:dicDCSpecialSids.ContainsKey($_.IdentityReference.toString()))
	{
		$strAccName = $global:dicDCSpecialSids.Item($_.IdentityReference.toString())
	}
    else
    {
        $strAccName = $_.IdentityReference.toString()
    }


        # Add Translated object GUID information to output
        if($chkBoxTranslateGUID.isChecked -eq $true)
        {
	        if($($_.InheritedObjectType.toString()) -ne "00000000-0000-0000-0000-000000000000" )
            {

                $strTranslatedInheritObjType = $(MapGUIDToMatchingName -strGUIDAsString $_.InheritedObjectType.toString() -Domain $global:strDomainDNName)
            }
            else
            {
                $strTranslatedInheritObjType = $($_.InheritedObjectType.toString())
            }
	        if($($_.ObjectType.toString()) -ne "00000000-0000-0000-0000-000000000000" )
            {

                $strTranslatedObjType = $(MapGUIDToMatchingName -strGUIDAsString $_.ObjectType.toString() -Domain $global:strDomainDNName)
            }
            else
            {
                $strTranslatedObjType = $($_.ObjectType.toString())
            }
        }
        else
        {
            $strTranslatedInheritObjType = $($_.InheritedObjectType.toString())
            $strTranslatedObjType = $($_.ObjectType.toString())
        }
        # Add Meta data info to output
        If ($ACLMeta -eq $true)
        {
            $strMetaData = $strACLDate.toString()+";" + $strInvocationID.toString()+";" +  $strOrgUSN.toString()+";"

        }
        else
        {
           $strMetaData = ";;;"
        }

        $ou+";"+`
	    $_.IdentityReference.toString()+";"+`
	    $_.ActiveDirectoryRights.toString()+";"+`
	    $_.InheritanceType.toString()+";"+`
	    $strTranslatedObjType+";"+`
	    $strTranslatedInheritObjType+";"+`
	    $_.ObjectFlags.toString()+";"+`
        $(if($_.AccessControlType)
        {
        $_.AccessControlType.toString()+";"
        }
        else
        {
        $_.AuditFlags.toString()+";"
        })+`
	    $_.IsInherited.toString()+";"+`
	    $_.InheritanceFlags.toString()+";"+`
        $_.PropagationFlags.toString()+";" + `
        $strMetaData | Out-File -Append -FilePath $fileout
        }
}
#==========================================================================
# Function		: ConvertSidTo-Name
# Arguments     : SID string
# Returns   	: Friendly Name of Security Object
# Description   : Try to translate the SID if it fails it try to match a Well-Known.
#==========================================================================
function ConvertSidTo-Name($server,$sid) {
$ID = New-Object System.Security.Principal.SecurityIdentifier($sid)

&{#Try
	$User = $ID.Translate( [System.Security.Principal.NTAccount])
	$strAccName = $User.Value
}
Trap [SystemException]
{
	If ($global:dicWellKnownSids.ContainsKey($sid))
	{
		$strAccName = $global:dicWellKnownSids.Item($sid)
		return $strAccName
	}
	;Continue
}
If ($global:dicSidToName.ContainsKey($sid))
{
	$strAccName =$global:dicSidToName.Item($sid)
}
else
{
	$objSID = [ADSI]"LDAP://$server/<SID=$sid>"
	$strAccName = $objSID.samAccountName
	$global:dicSidToName.Add($sid,$strAccName)
}
If ($strAccName -eq $nul)
{
	$strAccName =$sid
}

return $strAccName
}

#==========================================================================
# Function		: WriteHTM
# Arguments     : Security Descriptor, OU dn string, Output htm file
# Returns   	: n/a
# Description   : Wites the SD info to a HTM table, it appends info if the file exist
#==========================================================================
function WriteHTM([bool] $bolACLExist,$sd,[string]$ou,[bool] $OUHeader,[string] $strColorTemp,[string] $htmfileout,[bool] $CompareMode,[bool] $FilterMode,[bool]$boolReplMetaDate,[string]$strReplMetaDate,[bool]$boolACLSize,[string]$strACLSize,[bool]$boolOUProtected,[bool]$bolOUPRotected,[bool]$bolCriticalityLevel,[bool]$bolTranslateGUID)
{


$strTHOUColor = "E5CF00"
$strTHColor = "EFAC00"
$strLegendColor = ""
$strLegendTextVal = "Info"
$strLegendTextInfo = "Info"
$strLegendTextLow = "Low"
$strLegendTextMedium = "Medium"
$strLegendTextWarning = "Warning"
$strLegendTextCritical = "Critical"
$strLegendColorInfo=@"
bgcolor="#A4A4A4"
"@
$strLegendColorLow =@"
bgcolor="#0099FF"
"@
$strLegendColorMedium=@"
bgcolor="#FFFF00"
"@
$strLegendColorWarning=@"
bgcolor="#FFCC00"
"@
$strLegendColorCritical=@"
bgcolor="#DF0101"
"@
$strFont =@"
<FONT size="1" face="verdana, hevetica, arial">
"@
$strFontRights =@"
<FONT size="1" face="verdana, hevetica, arial">
"@
$strFontOU =@"
<FONT size="1" face="verdana, hevetica, arial">
"@
$strFontTH =@"
<FONT size="2" face="verdana, hevetica, arial">
"@
If ($OUHeader -eq $true)
{
$strHTMLText =@"
$strHTMLText
<TR bgcolor="$strTHOUColor"><TD><b>$strFontOU $ou</b>
"@

if ($boolReplMetaDate -eq $true)
{
$strHTMLText =@"
$strHTMLText
<TD><b>$strFontOU $strReplMetaDate</b>
"@
}
if ($boolACLSize -eq $true)
{
$strHTMLText =@"
$strHTMLText
<TD><b>$strFontOU $strACLSize bytes</b>
"@
}
if ($boolOUProtected -eq $true)
{
    if ($bolOUProtected -eq $true)
    {
$strHTMLText =@"
$strHTMLText
<TD bgcolor="FF0000"><b>$strFontOU $bolOUProtected</b>
"@
    }
    else
    {
$strHTMLText =@"
$strHTMLText
<TD><b>$strFontOU $bolOUProtected</b>
"@
    }
}

$strHTMLText =@"
$strHTMLText
</TR>
"@
}


Switch ($strColorTemp)
{

"1"
	{
	$strColor = "DDDDDD"
	$strColorTemp = "2"
	}
	"2"
	{
	$strColor = "AAAAAA"
	$strColorTemp = "1"
	}
"3"
	{
	$strColor = "FF1111"
}
"4"
	{
	$strColor = "00FFAA"
}
"5"
	{
	$strColor = "FFFF00"
}
	}# End Switch

if ($bolACLExist)
{
	$sd  | foreach{
    if($_.AccessControlType)
    {
    $objAccess = $($_.AccessControlType.toString())
    }
    else
    {
    $objAccess = $($_.AuditFlags.toString())
    }
	$objFlags = $($_.ObjectFlags.toString())
	$objType = $($_.ObjectType.toString())
	$objInheritedType = $($_.InheritedObjectType.toString())
	$objRights = $($_.ActiveDirectoryRights.toString())
    $objInheritanceType = $($_.InheritanceType.toString())



    if($chkBoxEffectiveRightsColor.IsChecked -eq $false)
    {
    	Switch ($objRights)
    	{
    		"DeleteChild, DeleteTree, Delete"
    		{
    			$objRights = "DeleteChild, DeleteTree, Delete"

    		}
    		"GenericRead"
    		{
    			$objRights = "Read Permissions,List Contents,Read All Properties,List"
            }
    		"CreateChild"
    		{
    			$objRights = "Create"
    		}
    		"DeleteChild"
    		{
    			$objRights = "Delete"
    		}
    		"GenericAll"
    		{
    			$objRights = "Full Control"
    		}
    		"CreateChild, DeleteChild"
    		{
    			$objRights = "Create/Delete"
    		}
    		"ReadProperty"
    		{
    	        Switch ($objInheritanceType)
    	        {
    	 	        "None"
    	 	        {

                        	 		Switch ($objFlags)
    	    	                {
    		      	                "ObjectAceTypePresent"
                    {
                       $objRights = "Read"
                    }

    		      	                "ObjectAceTypePresent, InheritedObjectAceTypePresent"
                    {
                       $objRights = "Read"
                    }
                      default
    	 	                        {$objRights = "Read All Properties"	}
                                }#End switch



                        }
                                  	 	        "Children"
    	 	        {

                        	 		Switch ($objFlags)
    	    	                {
    		      	                "ObjectAceTypePresent"
                    {
                       $objRights = "Read"
                    }

    		      	                "ObjectAceTypePresent, InheritedObjectAceTypePresent"
                    {
                       $objRights = "Read"
                    }
                      default
    	 	                        {$objRights = "Read All Properties"	}
                                }#End switch
                                }
                        	 	        "Descendents"
    	 	        {

                        	 		Switch ($objFlags)
    	    	                {
    		      	                "ObjectAceTypePresent"
                    {
                       $objRights = "Read"
                    }

    		      	                "ObjectAceTypePresent, InheritedObjectAceTypePresent"
                    {
                       $objRights = "Read"
                    }
                      default
    	 	                        {$objRights = "Read All Properties"	}
                                }#End switch
                                }
    	 	        default
    	 	        {$objRights = "Read All Properties"	}
                }#End switch


    		}
    		"ReadProperty, WriteProperty"
    		{
    			$objRights = "Read All Properties;Write All Properties"
    		}
    		"WriteProperty"
    		{
    	        Switch ($objInheritanceType)
    	        {
    	 	        "None"
    	 	        {

                        	 		Switch ($objFlags)
    	    	                {
    		      	                "ObjectAceTypePresent"
                    {
                       $objRights = "Write"
                    }

    		      	                "ObjectAceTypePresent, InheritedObjectAceTypePresent"
                    {
                       $objRights = "Write"
                    }
                      default
    	 	                        {$objRights = "Write All Properties"	}
                                }#End switch



                        }
                                  	 	        "Children"
    	 	        {

                        	 		Switch ($objFlags)
    	    	                {
    		      	                "ObjectAceTypePresent"
                    {
                       $objRights = "Write"
                    }

    		      	                "ObjectAceTypePresent, InheritedObjectAceTypePresent"
                    {
                       $objRights = "Write"
                    }
                      default
    	 	                        {$objRights = "Write All Properties"	}
                                }#End switch
                                }
                        	 	        "Descendents"
    	 	        {

                        	 		Switch ($objFlags)
    	    	                {
    		      	                "ObjectAceTypePresent"
                    {
                       $objRights = "Write"
                    }

    		      	                "ObjectAceTypePresent, InheritedObjectAceTypePresent"
                    {
                       $objRights = "Write"
                    }
                      default
    	 	                        {$objRights = "Write All Properties"	}
                                }#End switch
                                }
    	 	        default
    	 	        {$objRights = "Write All Properties"	}
                }#End switch
    		}
    	}# End Switch
    }
    else
    {

    	Switch ($objRights)
    	{
            "ListChildren"
            {
            If ($objAccess -eq "Allow")
            {
            $strLegendColor = $strLegendColorInfo
            $strLegendTextVal = $strLegendTextInfo
            }
            }
            "Modify permissions"
            {
            $strLegendColor = $strLegendColorCritical
            $strLegendTextVal = $strLegendTextCritical
            }
    		"DeleteChild, DeleteTree, Delete"
    		{
                If ($objAccess -eq "Allow")
                {
                $strLegendColor = $strLegendColorWarning
                $strLegendTextVal = $strLegendTextWarning
                }
    			$objRights = "DeleteChild, DeleteTree, Delete"

    		}
            "Delete"
            {
                If ($objAccess -eq "Allow")
                {
                $strLegendColor = $strLegendColorWarning
                $strLegendTextVal = $strLegendTextWarning
                }
            }
    		"GenericRead"
    		{
                If ($objAccess -eq "Allow")
                {
                $strLegendColor = $strLegendColorLow
                $strLegendTextVal = $strLegendTextLow
    			}
                $objRights = "Read Permissions,List Contents,Read All Properties,List"
            }
    		"CreateChild"
    		{
                If ($objAccess -eq "Allow")
                {
                $strLegendColor = $strLegendColorWarning
                $strLegendTextVal = $strLegendTextWarning
    			}
                $objRights = "Create"
    		}
    		"DeleteChild"
    		{
                If ($objAccess -eq "Allow")
                {
                $strLegendColor = $strLegendColorWarning
                $strLegendTextVal = $strLegendTextWarning
    			}
                $objRights = "Delete"
    		}
            "ExtendedRight"
            {
                If ($objAccess -eq "Allow")
                {
                $strLegendColor = $strLegendColorWarning
                $strLegendTextVal = $strLegendTextWarning
                }
            }
    		"GenericAll"
    		{
                If ($objAccess -eq "Allow")
                {
                $strLegendColor = $strLegendColorCritical
                $strLegendTextVal = $strLegendTextCritical
    			}
                $objRights = "Full Control"
    		}
    		"CreateChild, DeleteChild"
    		{
                If ($objAccess -eq "Allow")
                {
                $strLegendColor = $strLegendColorWarning
                $strLegendTextVal = $strLegendTextWarning
    			}
                $objRights = "Create/Delete"
    		}
    		"ReadProperty"
    		{
                If ($objAccess -eq "Allow")
                {
                $strLegendColor = $strLegendColorLow
                $strLegendTextVal = $strLegendTextLow
    	        }

                Switch ($objInheritanceType)
    	        {
    	 	        "None"
    	 	        {

                        	 		Switch ($objFlags)
    	    	                {
    		      	                "ObjectAceTypePresent"
                                        {

                                           $objRights = "Read"
                                        }

    		      	                "ObjectAceTypePresent, InheritedObjectAceTypePresent"
                                        {
                                           $objRights = "Read"
                                        }
                                    default
    	 	                            {$objRights = "Read All Properties"	}
                                    }#End switch



                 $strLegendColor = $strLegendColorLow
                $strLegendTextVal = $strLegendTextLow
                        }
                     "Children"
    	 	        {

                        	 		Switch ($objFlags)
    	    	                {
    		      	                "ObjectAceTypePresent"
                                {
                                   $objRights = "Read"
                                }

    		      	                            "ObjectAceTypePresent, InheritedObjectAceTypePresent"
                                {
                                   $objRights = "Read"
                                }
                                  default
    	 	                        {$objRights = "Read All Properties"	}
                                }#End switch

                 }
                        "Descendents"
    	 	    {

                        	 		Switch ($objFlags)
    	    	                {
    		      	                "ObjectAceTypePresent"
                    {
                       $objRights = "Read"
                    }

    		      	                "ObjectAceTypePresent, InheritedObjectAceTypePresent"
                    {
                       $objRights = "Read"
                    }
                      default
    	 	                        {$objRights = "Read All Properties"	}
                                }#End switch

                                }
    	 	        default
    	 	        {$objRights = "Read All Properties"	}
                }#End switch


    		}
    		"ReadProperty, WriteProperty"
    		{
                If ($objAccess -eq "Allow")
                {
                $strLegendTextVal = $strLegendTextMedium
                $strLegendColor = $strLegendColorMedium
    			}
                $objRights = "Read All Properties;Write All Properties"
    		}
    		"WriteProperty"
    		{
                If ($objAccess -eq "Allow")
                {
                $strLegendColor = $strLegendColorMedium
                $strLegendTextVal = $strLegendTextMedium
    	        }
                Switch ($objInheritanceType)
    	        {
    	 	        "None"
    	 	        {

                        Switch ($objFlags)
                        {
                            "ObjectAceTypePresent"
                            {
                               $objRights = "Write"
                            }

                            "ObjectAceTypePresent, InheritedObjectAceTypePresent"
                            {
                               $objRights = "Write"
                            }
                            default
                            {
                                $objRights = "Write All Properties"
                            }
                        }#End switch

                    }
                    "Children"
                    {

                        Switch ($objFlags)
                        {
                            "ObjectAceTypePresent"
                            {
                                $objRights = "Write"
                            }

                            "ObjectAceTypePresent, InheritedObjectAceTypePresent"
                            {
                                $objRights = "Write"
                            }
                            default
                            {
                                $objRights = "Write All Properties"
                            }
                        }#End switch
                    }
                    "Descendents"
                    {

                        Switch ($objFlags)
                        {
                            "ObjectAceTypePresent"
                            {
                                $objRights = "Write"
                            }
                            "ObjectAceTypePresent, InheritedObjectAceTypePresent"
                            {
                                $objRights = "Write"
                            }
                            default
                            {
                                $objRights = "Write All Properties"
                            }
                        }#End switch
                    }
                    default
                    {
                        $objRights = "Write All Properties"
                    }
                }#End switch
    		}
            default
            {
                If ($objAccess -eq "Allow")
                {
                     if($objRights -match "Write")
                    {
                     $strLegendColor = $strLegendColorMedium
                     $strLegendTextVal = $strLegendTextMedium
                    }
                     if($objRights -match "Create")
                    {
                     $strLegendColor = $strLegendColorWarning
                     $strLegendTextVal = $strLegendTextWarning
                    }
                     if($objRights -match "Delete")
                    {
                     $strLegendColor = $strLegendColorWarning
                      $strLegendTextVal = $strLegendTextWarning
                    }
                    if($objRights -match "ExtendedRight")
                    {
                     $strLegendColor = $strLegendColorWarning
                      $strLegendTextVal = $strLegendTextWarning
                    }
                    if($objRights -match "WriteDacl")
                    {
                     $strLegendColor = $strLegendColorCritical
                      $strLegendTextVal = $strLegendTextCritical
                    }
                    if($objRights -match "WriteOwner")
                    {
                     $strLegendColor = $strLegendColorCritical
                     $strLegendTextVal = $strLegendTextCritical
                    }
                }
            }
    	}# End Switch
    }
	$strNTAccount = $($_.IdentityReference.toString())

	If ($strNTAccount.contains("S-1-5"))
	{
	 $strNTAccount = ConvertSidTo-Name -server $global:strDomainLongName -Sid $strNTAccount

	}

    Switch ($strColorTemp)
    {

    "1"
	{
	$strColor = "DDDDDD"
	$strColorTemp = "2"
	}
	"2"
	{
	$strColor = "AAAAAA"
	$strColorTemp = "1"
	}
    "3"
	{
	$strColor = "FF1111"
    }
    "4"
	{
	$strColor = "00FFAA"
    }
    "5"
	{
	$strColor = "FFFF00"
    }
	}# End Switch

	 Switch ($objInheritanceType)
	 {
	 	"All"
	 	{
	 		Switch ($objFlags)
	    	{
		      	"InheritedObjectAceTypePresent"
		      	{
		      		$strPerm =  "$strFont This object and all child objects</TD><TD $strLegendColor>$strFontRights $objRights $(if($bolTranslateGUID){$objInheritedType}else{MapGUIDToMatchingName -strGUIDAsString $objInheritedType -Domain $global:strDomainDNName})</TD>"
		      	}
		      	"ObjectAceTypePresent"
		      	{
		      		$strPerm =  "$strFont This object and all child objects</TD><TD $strLegendColor>$strFontRights $objRights $(if($bolTranslateGUID){$objType}else{MapGUIDToMatchingName -strGUIDAsString $objType -Domain $global:strDomainDNName})</TD>"
		      	}
		      	"ObjectAceTypePresent, InheritedObjectAceTypePresent"
		      	{
		      		$strPerm =  "$strFont $(if($bolTranslateGUID){$objInheritedType}else{MapGUIDToMatchingName -strGUIDAsString $objInheritedType -Domain $global:strDomainDNName})</TD><TD $strLegendColor>$strFontRights $objRights $(if($bolTranslateGUID){$objType}else{MapGUIDToMatchingName -strGUIDAsString $objType -Domain $global:strDomainDNName})</TD>"
		      	}
		      	"None"
		      	{
		      		$strPerm ="$strFont This object and all child objects</TD><TD $strLegendColor>$strFontRights $objRights</TD>"
		      	}
		      		default
	 		    {
		      		$strPerm = "Error: Failed to display permissions 1K"
		      	}

		    }# End Switch

	 	}
	 	"Descendents"
	 	{

	 		Switch ($objFlags)
	    	{
		      	"InheritedObjectAceTypePresent"
		      	{
		      	$strPerm = "$strFont $(if($bolTranslateGUID){$objInheritedType}else{MapGUIDToMatchingName -strGUIDAsString $objInheritedType -Domain $global:strDomainDNName})</TD><TD $strLegendColor>$strFontRights $objRights</TD>"
		      	}
		      	"None"
		      	{
		      		$strPerm ="$strFont Child Objects Only</TD><TD $strLegendColor>$strFontRights $objRights</TD>"
		      	}
		      	"ObjectAceTypePresent"
		      	{
		      		$strPerm = "$strFont Child Objects Only</TD><TD $strLegendColor>$strFontRights $objRights $(if($bolTranslateGUID){$objType}else{MapGUIDToMatchingName -strGUIDAsString $objType -Domain $global:strDomainDNName})</TD>"
		      	}
		      	"ObjectAceTypePresent, InheritedObjectAceTypePresent"
		      	{
		      		$strPerm =	"$strFont $(if($bolTranslateGUID){$objInheritedType}else{MapGUIDToMatchingName -strGUIDAsString $objInheritedType -Domain $global:strDomainDNName})</TD><TD $strLegendColor>$strFontRights $objRights $(if($bolTranslateGUID){$objType}else{MapGUIDToMatchingName -strGUIDAsString $objType -Domain $global:strDomainDNName})</TD>"
		      	}
		      	default
	 			{
		      		$strPerm = "Error: Failed to display permissions 2K"
		      	}

		    }
	 	}
	 	"None"
	 	{
	 		Switch ($objFlags)
	    	{
		      	"ObjectAceTypePresent"
		      	{
		      		$strPerm = "$strFont This Object Only</TD><TD $strLegendColor>$strFontRights $objRights $(if($bolTranslateGUID){$objType}else{MapGUIDToMatchingName -strGUIDAsString $objType -Domain $global:strDomainDNName}) </TD>"
		      	}
		      	"None"
		      	{
		      		$strPerm ="$strFont This Object Only</TD><TD $strLegendColor>$strFontRights $objRights </TD>"
		      	}
		      		default
	 		{
		      		$strPerm = "Error: Failed to display permissions 4K"
		      	}

			}
	 	}
	 	"SelfAndChildren"
	 	{
	 	 		Switch ($objFlags)
	    	{
		      	"ObjectAceTypePresent"
	      		{
		      		$strPerm = "$strFont This object and all child objects within this conatainer only</TD><TD $strLegendColor>$strFontRights $objRights $(if($bolTranslateGUID){$objType}else{MapGUIDToMatchingName -strGUIDAsString $objType -Domain $global:strDomainDNName})</TD>"
		      	}
		      	"InheritedObjectAceTypePresent"
		      	{
		      		$strPerm = "$strFont Children within this conatainer only</TD><TD $strLegendColor>$strFontRights $objRights $(if($bolTranslateGUID){$objInheritedType}else{MapGUIDToMatchingName -strGUIDAsString $objInheritedType -Domain $global:strDomainDNName})</TD>"
		      	}

		      	"ObjectAceTypePresent, InheritedObjectAceTypePresent"
		      	{
		      		$strPerm =  "$strFont $(if($bolTranslateGUID){$objInheritedType}else{MapGUIDToMatchingName -strGUIDAsString $objInheritedType -Domain $global:strDomainDNName})</TD><TD $strLegendColor>$strFontRights $objRights $(if($bolTranslateGUID){$objType}else{MapGUIDToMatchingName -strGUIDAsString $objType -Domain $global:strDomainDNName})</TD>"
		      	}
		      	"None"
		      	{
		      		$strPerm ="$strFont This object and all child objects</TD><TD $strLegendColor>$strFontRights $objRights</TD>"
		      	}
		      	default
	 		    {
		      		$strPerm = "Error: Failed to display permissions 5K"
		      	}

			}
	 	}
	 	"Children"
	 	{
	 	 		Switch ($objFlags)
	    	{
		      	"InheritedObjectAceTypePresent"
		      	{
		      		$strPerm = "$strFont Children within this conatainer only</TD><TD $strLegendColor>$strFontRights $objRights $(if($bolTranslateGUID){$objInheritedType}else{MapGUIDToMatchingName -strGUIDAsString $objInheritedType -Domain $global:strDomainDNName})</TD>"
		      	}
		      	"None"
		      	{
		      		$strPerm = "$strFont Children  within this conatainer only</TD><TD $strLegendColor>$strFontRights $objRights</TD>"
		      	}
		      	"ObjectAceTypePresent, InheritedObjectAceTypePresent"
	      		{
		      		$strPerm = "$strFont $(if($bolTranslateGUID){$objInheritedType}else{MapGUIDToMatchingName -strGUIDAsString $objInheritedType -Domain $global:strDomainDNName})</TD><TD>$strFont $(if($bolTranslateGUID){$objType}else{MapGUIDToMatchingName -strGUIDAsString $objType -Domain $global:strDomainDNName}) $objRights</TD>"
		      	}
		      	"ObjectAceTypePresent"
	      		{
		      		$strPerm = "$strFont Children within this conatainer only</TD><TD $strLegendColor>$strFontRights $objRights $(if($bolTranslateGUID){$objType}else{MapGUIDToMatchingName -strGUIDAsString $objType -Domain $global:strDomainDNName})</TD>"
		      	}
		      	default
	 			{
		      		$strPerm = "Error: Failed to display permissions 6K"
		      	}

	 		}
	 	}
	 	default
	 		{
		      		$strPerm = "Error: Failed to display permissions 7K"
		    }
	}# End Switch

##


$strACLHTMLText =@"
$strACLHTMLText
<TR bgcolor="$strColor"><TD>$strFont $ou</TD>
"@


if ($boolReplMetaDate -eq $true)
{
$strACLHTMLText =@"
$strACLHTMLText
<TD>$strFont $strReplMetaDate</TD>
"@
}

if ($boolACLSize -eq $true)
{
$strACLHTMLText =@"
$strACLHTMLText
<TD>$strFont $strACLSize bytes</TD>
"@
}

if ($boolOUProtected -eq $true)
{
$strACLHTMLText =@"
$strACLHTMLText
<TD>$strFont $bolOUPRotected </TD>
"@
}
$strACLHTMLText =@"
$strACLHTMLText
<TD>$strFont $strNTAccount</TD>
<TD>$strFont $(if($_.AccessControlType){$_.AccessControlType.toString()}else{$_.AuditFlags.toString()}) </TD>
<TD>$strFont $($_.IsInherited.toString())</TD>
<TD>$strPerm</TD>
"@

if($CompareMode)
{

$strACLHTMLText =@"
$strACLHTMLText
<TD>$strFont $($_.color.toString())</TD>
"@
}
if ($bolCriticalityLevel -eq $true)
{
$strACLHTMLText =@"
$strACLHTMLText
<TD $strLegendColor>$strFont $strLegendTextVal</TD>
"@
}
}# End Foreach


}
else
{
if ($OUHeader -eq $false)
{
if ($FilterMode)
{



if ($boolReplMetaDate -eq $true)
{
$strACLHTMLText =@"
$strACLHTMLText
<TD>$strFont $strReplMetaDate</TD>
"@
}

if ($boolACLSize -eq $true)
{
$strACLHTMLText =@"
$strACLHTMLText
<TD>$strFont $strACLSize bytes</TD>
"@
}

if ($boolOUProtected -eq $true)
{
$strACLHTMLText =@"
$strACLHTMLText
<TD>$strFont $bolOUPRotected </TD>
"@
}
$strACLHTMLText =@"
$strACLHTMLText
<TD>$strFont N/A</TD>
<TD>$strFont N/A</TD>
<TD>$strFont N/A</TD><
<TD>$strFont N/A</TD>
<TD>$strFont No Matching Permissions Set</TD>
"@



if ($bolCriticalityLevel -eq $true)
{
$strACLHTMLText =@"
$strACLHTMLText
<TD $strLegendColor>$strFont $strLegendTextVal</TD>
"@
}
}
else
{


if ($boolReplMetaDate -eq $true)
{
$strACLHTMLText =@"
$strACLHTMLText
<TD>$strFont $strReplMetaDate</TD>
"@
}

if ($boolACLSize -eq $true)
{
$strACLHTMLText =@"
$strACLHTMLText
<TD>$strFont $strACLSize bytes</TD>
"@
}

if ($boolOUProtected -eq $true)
{
$strACLHTMLText =@"
$strACLHTMLText
<TD>$strFont $bolOUPRotected </TD>
"@
}

$strACLHTMLText =@"
$strACLHTMLText
<TD>$strFont N/A</TD>
<TD>$strFont N/A</TD>
<TD>$strFont N/A</TD><
<TD>$strFont N/A</TD>
<TD>$strFont No Permissions Set</TD>
"@


if ($bolCriticalityLevel -eq $true)
{
$strACLHTMLText =@"
$strACLHTMLText
<TD $strLegendColor>$strFont $strLegendTextVal</TD>
"@
}

}# End If
}#end If OUHeader false
}
$strACLHTMLText =@"
$strACLHTMLText
</TR>
"@

#end ifelse OUHEader
$strHTMLText = $strHTMLText + $strACLHTMLText

Out-File -InputObject $strHTMLText -Append -FilePath $htmfileout
Out-File -InputObject $strHTMLText -Append -FilePath $strFileHTM

$strHTMLText = $null
$strACLHTMLText = $null
Remove-Variable -Name "strHTMLText"
Remove-Variable -Name "strACLHTMLText"

}


#==========================================================================
# Function		: InitiateHTM
# Arguments     : Output htm file
# Returns   	: n/a
# Description   : Wites base HTM table syntax, it appends info if the file exist
#==========================================================================
Function InitiateHTM([string] $htmfileout,[bool]$RepMetaDate ,[bool]$ACLSize,[bool]$bolACEOUProtected,[bool]$bolCirticaltiy,[bool]$bolCompare)
{
$strHTMLText ="<TABLE BORDER=1>"
$strTHOUColor = "E5CF00"
$strTHColor = "EFAC00"
$strFont =@"
<FONT size="1" face="verdana, hevetica, arial">
"@
$strFontOU =@"
<FONT size="1" face="verdana, hevetica, arial">
"@
$strFontTH =@"
<FONT size="2" face="verdana, hevetica, arial">
"@
$strHTMLText =@"
$strHTMLText
<th bgcolor="$strTHColor">$strFontTH OU</font></th>
"@
if ($RepMetaDate -eq $true)
{
$strHTMLText =@"
$strHTMLText
<th bgcolor="$strTHColor">$strFontTH Security Descriptor Modified</font>
"@
}
if ($ACLSize -eq $true)
{
$strHTMLText =@"
$strHTMLText
<th bgcolor="$strTHColor">$strFontTH DACL Size</font>
"@
}
if ($bolACEOUProtected -eq $true)
{
$strHTMLText =@"
$strHTMLText
<th bgcolor="$strTHColor">$strFontTH Inheritance Disabled</font>
"@
}
$strHTMLText =@"
$strHTMLText
</th><th bgcolor="$strTHColor">$strFontTH Trustee</font></th><th bgcolor="$strTHColor">$strFontTH Right</font></th><th bgcolor="$strTHColor">$strFontTH Inherited</font></th><th bgcolor="$strTHColor">$strFontTH Apply To</font></th><th bgcolor="$strTHColor">$strFontTH Permission</font></th>
"@

if ($bolCompare -eq $true)
{
$strHTMLText =@"
$strHTMLText
<th bgcolor="$strTHColor">$strFontTH State</font></th>
"@
}


if ($bolCirticaltiy -eq $true)
{
$strHTMLText =@"
$strHTMLText
<th bgcolor="$strTHColor">$strFontTH Criticality Level</font></th>
"@
}



Out-File -InputObject $strHTMLText -Append -FilePath $htmfileout
$strHTMLText = $null
$strTHOUColor = $null
$strTHColor = $null
Remove-Variable -Name "strHTMLText"
Remove-Variable -Name "strTHOUColor"
Remove-Variable -Name "strTHColor"


}
#==========================================================================
# Function		: InitiateHTM
# Arguments     : Output htm file
# Returns   	: n/a
# Description   : Wites base HTM table syntax, it appends info if the file exist
#==========================================================================
Function InitiateCompareHTM([string] $htmfileout,[bool]$RepMetaDate ,[bool]$ACLSize,[bool]$bolACEOUProtected,[bool]$bolCirticaltiy)
{
$strHTMLText ="<TABLE BORDER=1>"
$strTHOUColor = "E5CF00"
$strTHColor = "EFAC00"
$strFont =@"
<FONT size="1" face="verdana, hevetica, arial">
"@
$strFontOU =@"
<FONT size="1" face="verdana, hevetica, arial">
"@
$strFontTH =@"
<FONT size="2" face="verdana, hevetica, arial">
"@
if ($RepMetaDate -eq $true)
{
if ($ACLSize -eq $true)
{
if ($bolACEOUProtected -eq $true)
{
if ($bolCirticaltiy -eq $true)
{
$strHTMLText =@"
$strHTMLText
<th bgcolor="$strTHColor">$strFontTH Security Descriptor Modified</font><th bgcolor="$strTHColor">$strFontTH DACL Size</font><th bgcolor="$strTHColor">$strFontTH Inheritance Disabled</font><th bgcolor="$strTHColor">$strFontTH OU</font></th><th bgcolor="$strTHColor">$strFontTH Trustee</font></th><th bgcolor="$strTHColor">$strFontTH Right</font></th><th bgcolor="$strTHColor">$strFontTH Inherited</font></th><th bgcolor="$strTHColor">$strFontTH Apply To</font></th><th bgcolor="$strTHColor">$strFontTH Permission</font></th><th bgcolor="$strTHColor">$strFontTH Criticality Level</font></th><th bgcolor="$strTHColor">$strFontTH State</font></th>
"@
}
else
{
$strHTMLText =@"
$strHTMLText
<th bgcolor="$strTHColor">$strFontTH Security Descriptor Modified</font><th bgcolor="$strTHColor">$strFontTH DACL Size</font><th bgcolor="$strTHColor">$strFontTH Inheritance Disabled</font><th bgcolor="$strTHColor">$strFontTH OU</font></th><th bgcolor="$strTHColor">$strFontTH Trustee</font></th><th bgcolor="$strTHColor">$strFontTH Right</font></th><th bgcolor="$strTHColor">$strFontTH Inherited</font></th><th bgcolor="$strTHColor">$strFontTH Apply To</font></th><th bgcolor="$strTHColor">$strFontTH Permission</font></th><th bgcolor="$strTHColor">$strFontTH State</font></th>
"@
}
}
else
{
if ($bolCirticaltiy -eq $true)
{
$strHTMLText =@"
$strHTMLText
<th bgcolor="$strTHColor">$strFontTH Security Descriptor Modified</font><th bgcolor="$strTHColor">$strFontTH DACL Size</font><th bgcolor="$strTHColor">$strFontTH OU</font></th><th bgcolor="$strTHColor">$strFontTH Trustee</font></th><th bgcolor="$strTHColor">$strFontTH Right</font></th><th bgcolor="$strTHColor">$strFontTH Inherited</font></th><th bgcolor="$strTHColor">$strFontTH Apply To</font></th><th bgcolor="$strTHColor">$strFontTH Permission</font></th><th bgcolor="$strTHColor">$strFontTH Criticality Level</font></th><th bgcolor="$strTHColor">$strFontTH State</font></th>
"@
}
else
{
$strHTMLText =@"
$strHTMLText
<th bgcolor="$strTHColor">$strFontTH Security Descriptor Modified</font><th bgcolor="$strTHColor">$strFontTH DACL Size</font><th bgcolor="$strTHColor">$strFontTH OU</font></th><th bgcolor="$strTHColor">$strFontTH Trustee</font></th><th bgcolor="$strTHColor">$strFontTH Right</font></th><th bgcolor="$strTHColor">$strFontTH Inherited</font></th><th bgcolor="$strTHColor">$strFontTH Apply To</font></th><th bgcolor="$strTHColor">$strFontTH Permission</font></th><th bgcolor="$strTHColor">$strFontTH State</font></th>
"@
}
}
}
else
{
if ($bolACEOUProtected -eq $true)
{
if ($bolCirticaltiy -eq $true)
{
$strHTMLText =@"
$strHTMLText
<th bgcolor="$strTHColor">$strFontTH Security Descriptor Modified</font><th bgcolor="$strTHColor">$strFontTH Inheritance Disabled</font><th bgcolor="$strTHColor">$strFontTH OU</font></th><th bgcolor="$strTHColor">$strFontTH Trustee</font></th><th bgcolor="$strTHColor">$strFontTH Right</font></th><th bgcolor="$strTHColor">$strFontTH Inherited</font></th><th bgcolor="$strTHColor">$strFontTH Apply To</font></th><th bgcolor="$strTHColor">$strFontTH Permission</font></th><th bgcolor="$strTHColor">$strFontTH Criticality Level</font></th><th bgcolor="$strTHColor">$strFontTH State</font></th>
"@
}
else
{
$strHTMLText =@"
$strHTMLText
<th bgcolor="$strTHColor">$strFontTH Security Descriptor Modified</font><th bgcolor="$strTHColor">$strFontTH Inheritance Disabled</font><th bgcolor="$strTHColor">$strFontTH OU</font></th><th bgcolor="$strTHColor">$strFontTH Trustee</font></th><th bgcolor="$strTHColor">$strFontTH Right</font></th><th bgcolor="$strTHColor">$strFontTH Inherited</font></th><th bgcolor="$strTHColor">$strFontTH Apply To</font></th><th bgcolor="$strTHColor">$strFontTH Permission</font></th><th bgcolor="$strTHColor">$strFontTH State</font></th>
"@
}
}
else
{
if ($bolCirticaltiy -eq $true)
{
$strHTMLText =@"
$strHTMLText
<th bgcolor="$strTHColor">$strFontTH Security Descriptor Modified</font><th bgcolor="$strTHColor">$strFontTH OU</font></th><th bgcolor="$strTHColor">$strFontTH Trustee</font></th><th bgcolor="$strTHColor">$strFontTH Right</font></th><th bgcolor="$strTHColor">$strFontTH Inherited</font></th><th bgcolor="$strTHColor">$strFontTH Apply To</font></th><th bgcolor="$strTHColor">$strFontTH Permission</font></th><th bgcolor="$strTHColor">$strFontTH Criticality Level</font></th><th bgcolor="$strTHColor">$strFontTH State</font></th>
"@
}
else
{
$strHTMLText =@"
$strHTMLText
<th bgcolor="$strTHColor">$strFontTH Security Descriptor Modified</font><th bgcolor="$strTHColor">$strFontTH OU</font></th><th bgcolor="$strTHColor">$strFontTH Trustee</font></th><th bgcolor="$strTHColor">$strFontTH Right</font></th><th bgcolor="$strTHColor">$strFontTH Inherited</font></th><th bgcolor="$strTHColor">$strFontTH Apply To</font></th><th bgcolor="$strTHColor">$strFontTH Permission</font></th><th bgcolor="$strTHColor">$strFontTH State</font></th>
"@
}
}
}
}
else
{
if ($ACLSize -eq $true)
{
if ($bolACEOUProtected -eq $true)
{
if ($bolCirticaltiy -eq $true)
{
$strHTMLText =@"
$strHTMLText
<th bgcolor="$strTHColor">$strFontTH DACL Size</font><th bgcolor="$strTHColor">$strFontTH Inheritance Disabled</font><th bgcolor="$strTHColor">$strFontTH OU</font></th><th bgcolor="$strTHColor">$strFontTH Trustee</font></th><th bgcolor="$strTHColor">$strFontTH Right</font></th><th bgcolor="$strTHColor">$strFontTH Inherited</font></th><th bgcolor="$strTHColor">$strFontTH Apply To</font></th><th bgcolor="$strTHColor">$strFontTH Permission</font></th><th bgcolor="$strTHColor">$strFontTH Criticality Level</font></th><th bgcolor="$strTHColor">$strFontTH State</font></th>
"@
}
else
{
$strHTMLText =@"
$strHTMLText
<th bgcolor="$strTHColor">$strFontTH DACL Size</font><th bgcolor="$strTHColor">$strFontTH Inheritance Disabled</font><th bgcolor="$strTHColor">$strFontTH OU</font></th><th bgcolor="$strTHColor">$strFontTH Trustee</font></th><th bgcolor="$strTHColor">$strFontTH Right</font></th><th bgcolor="$strTHColor">$strFontTH Inherited</font></th><th bgcolor="$strTHColor">$strFontTH Apply To</font></th><th bgcolor="$strTHColor">$strFontTH Permission</font></th><th bgcolor="$strTHColor">$strFontTH State</font></th>
"@
}
}
else
{
if ($bolCirticaltiy -eq $true)
{
$strHTMLText =@"
$strHTMLText
<th bgcolor="$strTHColor">$strFontTH DACL Size</font><th bgcolor="$strTHColor">$strFontTH OU</font></th><th bgcolor="$strTHColor">$strFontTH Trustee</font></th><th bgcolor="$strTHColor">$strFontTH Right</font></th><th bgcolor="$strTHColor">$strFontTH Inherited</font></th><th bgcolor="$strTHColor">$strFontTH Apply To</font></th><th bgcolor="$strTHColor">$strFontTH Permission</font></th><th bgcolor="$strTHColor">$strFontTH Criticality Level</font></th><th bgcolor="$strTHColor">$strFontTH State</font></th>
"@
}
else
{
$strHTMLText =@"
$strHTMLText
<th bgcolor="$strTHColor">$strFontTH DACL Size</font><th bgcolor="$strTHColor">$strFontTH OU</font></th><th bgcolor="$strTHColor">$strFontTH Trustee</font></th><th bgcolor="$strTHColor">$strFontTH Right</font></th><th bgcolor="$strTHColor">$strFontTH Inherited</font></th><th bgcolor="$strTHColor">$strFontTH Apply To</font></th><th bgcolor="$strTHColor">$strFontTH Permission</font></th><th bgcolor="$strTHColor">$strFontTH State</font></th>
"@
}
}
}
else
{
if ($bolACEOUProtected -eq $true)
{
if ($bolCirticaltiy -eq $true)
{
$strHTMLText =@"
$strHTMLText
<th bgcolor="$strTHColor">$strFontTH Inheritance Disabled</font><th bgcolor="$strTHColor">$strFontTH OU</font></th><th bgcolor="$strTHColor">$strFontTH Trustee</font></th><th bgcolor="$strTHColor">$strFontTH Right</font></th><th bgcolor="$strTHColor">$strFontTH Inherited</font></th><th bgcolor="$strTHColor">$strFontTH Apply To</font></th><th bgcolor="$strTHColor">$strFontTH Permission</font></th><th bgcolor="$strTHColor">$strFontTH Criticality Level</font></th><th bgcolor="$strTHColor">$strFontTH State</font></th>
"@
}
else
{
$strHTMLText =@"
$strHTMLText
<th bgcolor="$strTHColor">$strFontTH Inheritance Disabled</font><th bgcolor="$strTHColor">$strFontTH OU</font></th><th bgcolor="$strTHColor">$strFontTH Trustee</font></th><th bgcolor="$strTHColor">$strFontTH Right</font></th><th bgcolor="$strTHColor">$strFontTH Inherited</font></th><th bgcolor="$strTHColor">$strFontTH Apply To</font></th><th bgcolor="$strTHColor">$strFontTH Permission</font></th><th bgcolor="$strTHColor">$strFontTH State</font></th>
"@
}
}
else
{
if ($bolCirticaltiy -eq $true)
{
$strHTMLText =@"
$strHTMLText
<th bgcolor="$strTHColor">$strFontTH OU</font></th><th bgcolor="$strTHColor">$strFontTH Trustee</font></th><th bgcolor="$strTHColor">$strFontTH Right</font></th><th bgcolor="$strTHColor">$strFontTH Inherited</font></th><th bgcolor="$strTHColor">$strFontTH Apply To</font></th><th bgcolor="$strTHColor">$strFontTH Permission</font></th><th bgcolor="$strTHColor">$strFontTH Criticality Level</font></th><th bgcolor="$strTHColor">$strFontTH State</font></th>
"@
}
else
{
$strHTMLText =@"
$strHTMLText
<th bgcolor="$strTHColor">$strFontTH OU</font></th><th bgcolor="$strTHColor">$strFontTH Trustee</font></th><th bgcolor="$strTHColor">$strFontTH Right</font></th><th bgcolor="$strTHColor">$strFontTH Inherited</font></th><th bgcolor="$strTHColor">$strFontTH Apply To</font></th><th bgcolor="$strTHColor">$strFontTH Permission</font></th><th bgcolor="$strTHColor">$strFontTH State</font></th>
"@
}
}
}

}
Out-File -InputObject $strHTMLText -Append -FilePath $htmfileout
}
#==========================================================================
# Function		: InitiateCompareHTM
# Arguments     : Output htm file
# Returns   	: n/a
# Description   : Wites base HTM table syntax, it appends info if the file exist
#==========================================================================
Function InitiateCompareHTM2([string] $htmfileout,[boolean]$RepMetaDate)
{
$strHTMLText ="<TABLE BORDER=1>"
$strTHOUColor = "E5CF00"
$strTHColor = "EFAC00"
$strFont =@"
<FONT size="1" face="verdana, hevetica, arial">
"@
$strFontOU =@"
<FONT size="1" face="verdana, hevetica, arial">
"@
$strFontTH =@"
<FONT size="2" face="verdana, hevetica, arial">
"@
if ($RepMetaDate -eq $true)
{
$strHTMLText =@"
$strHTMLText
<th bgcolor="$strTHColor">$strFontTH Security Descriptor Modified</font><th bgcolor="$strTHColor">$strFontTH OU</font></th><th bgcolor="$strTHColor">$strFontTH Trustee</font></th><th bgcolor="$strTHColor">$strFontTH Right</font></th><th bgcolor="$strTHColor">$strFontTH Inherited</font></th><th bgcolor="$strTHColor">$strFontTH Apply To</font></th><th bgcolor="$strTHColor">$strFontTH Permission</font></th><th bgcolor="$strTHColor">$strFontTH State</font></th>
"@
}
else
{
$strHTMLText =@"
$strHTMLText
<th bgcolor="$strTHColor">$strFontTH OU</font></th><th bgcolor="$strTHColor">$strFontTH Trustee</font></th><th bgcolor="$strTHColor">$strFontTH Right</font></th><th bgcolor="$strTHColor">$strFontTH Inherited</font></th><th bgcolor="$strTHColor">$strFontTH Apply To</font></th><th bgcolor="$strTHColor">$strFontTH Permission</font></th><th bgcolor="$strTHColor">$strFontTH State</font></th>
"@
}
Out-File -InputObject $strHTMLText -Append -FilePath $htmfileout
}
#==========================================================================
# Function		: CreateHTA
# Arguments     : OU Name, Ou put HTA file
# Returns   	: n/a
# Description   : Initiates a base HTA file with Export(Save As),Print and Exit buttons.
#==========================================================================
function CreateHTA([string]$NodeName,[string]$htafileout,[string]$htmfileout,[string] $folder)
{
$strHTAText =@"
<html>
<head>
<hta:Application ID="hta"
ApplicationName="Report">
<title>Report on $NodeName</title>
<script type="text/vbscript">
Sub ExportToCSV()
Dim objFSO,objFile,objNewFile,oShell,oEnv
Set oShell=CreateObject("wscript.shell")
Set oEnv=oShell.Environment("System")
strTemp=oShell.ExpandEnvironmentStrings("%USERPROFILE%")
strTempFile="$htmfileout"
strOutputFolder="$folder"
strFile=SaveAs("$NodeName.htm",strOutputFolder)
If strFile="" Then Exit Sub
Set objFSO=CreateObject("Scripting.FileSystemObject")
objFSO.CopyFile strTempFile,strFile, true
MsgBox "Finished exporting to " & strFile,vbOKOnly+vbInformation,"Export"
End Sub
Function SaveAs(strFile,strOutFolder)
Dim objDialog
SaveAs=InputBox("Enter the filename and path."&vbCrlf&vbCrlf&"Example: "&strOutFolder&"\CONTOSO-contoso.htm","Export",strOutFolder&"\"&strFile)
End Function
</script>
</head>
<body>
<input type="button" value="Export" onclick="ExportToCSV" tabindex="9">
<input id="print_button" type="button" value="Print" name="Print_button" class="Hide" onClick="Window.print()">
<input type="button" value="Exit" onclick=self.close name="B3" tabindex="1" class="btn">
"@
Out-File -InputObject $strHTAText -Force -FilePath $htafileout
}
#==========================================================================
# Function		: WriteSPNHTM
# Arguments     : Security Principal Name,  Output htm file
# Returns   	: n/a
# Description   : Wites the account membership info to a HTM table, it appends info if the file exist
#==========================================================================
function WriteSPNHTM([string] $strSPN,$tokens,[string]$objType,[int]$intMemberOf,[string] $strColorTemp,[string] $htafileout,[string] $htmfileout)
{


$strTHOUColor = "E5CF00"
$strTHColor = "EFAC00"
$strFont =@"
<FONT size="1" face="verdana, hevetica, arial">
"@
$strFontOU =@"
<FONT size="1" face="verdana, hevetica, arial">
"@
$strFontTH =@"
<FONT size="2" face="verdana, hevetica, arial">
"@

$strHTMLText =@"
<TR bgcolor="$strTHOUColor"><TD><b>$strFontOU $strSPN</b><TD><b>$strFontOU $objType</b><TD><b>$strFontOU $intMemberOf</b></TR>
"@
$strHTMLText =@"
$strHTMLText
<TR bgcolor="$strTHColor"><TD><b>$strFontTH Groups</b></TD><TD></TD><TD></TD></TR>
"@


$tokens  | foreach{
if ($($_.toString()) -ne $strSPN)
{
Switch ($strColorTemp)
{

"1"
	{
	$strColor = "DDDDDD"
	$strColorTemp = "2"
	}
	"2"
	{
	$strColor = "AAAAAA"
	$strColorTemp = "1"
	}
"3"
	{
	$strColor = "FF1111"
}
"4"
	{
	$strColor = "00FFAA"
}
"5"
	{
	$strColor = "FFFF00"
}
	}# End Switch
$strGroupText=$strGroupText+@"
<TR bgcolor="$strColor"><TD>
$strFont $($_.toString())</TD></TR>
"@
}
}
$strHTMLText = $strHTMLText + $strGroupText


Out-File -InputObject $strHTMLText -Append -FilePath $htafileout
Out-File -InputObject $strHTMLText -Append -FilePath $htmfileout

$strHTMLText = ""

}
#==========================================================================
# Function		: CreateColorLegenedReportHTA
# Arguments     : OU Name, Ou put HTA file
# Returns   	: n/a
# Description   : Initiates a base HTA file with Export(Save As),Print and Exit buttons.
#==========================================================================
function CreateColorLegenedReportHTA([string]$htafileout)
{
$strHTAText =@"
<html>
<head>
<hta:Application ID="hta"
ApplicationName="Legend">
<title>Color Code</title>
<script type="text/vbscript">
Sub Window_Onload

 	self.ResizeTo 500,500
End sub
</script>
</head>
<body>

<input type="button" value="Exit" onclick=self.close name="B3" tabindex="1" class="btn">
"@

$strTHOUColor = "E5CF00"
$strTHColor = "EFAC00"
$strFont =@"
<FONT size="1" face="verdana, hevetica, arial">
"@
$strFontOU =@"
<FONT size="1" face="verdana, hevetica, arial">
"@
$strFontTH =@"
<FONT size="2" face="verdana, hevetica, arial">
"@
$strLegendColorInfo=@"
bgcolor="#A4A4A4"
"@
$strLegendColorLow =@"
bgcolor="#0099FF"
"@
$strLegendColorMedium=@"
bgcolor="#FFFF00"
"@
$strLegendColorWarning=@"
bgcolor="#FFCC00"
"@
$strLegendColorCritical=@"
bgcolor="#DF0101"
"@

$strHTAText =@"
$strHTAText
<h4>Use colors in report to identify criticality level of permissions.<br>This might help you in implementing <B>Least-Privilege</B> Administrative Models.</h4>
<TABLE BORDER=1>
<th bgcolor="$strTHColor">$strFontTH Permissions</font></th><th bgcolor="$strTHColor">$strFontTH Criticality</font></th>
<TR><TD> $strFontTH <B>Deny Permissions<TD $strLegendColorInfo> Info</TR>
<TR><TD> $strFontTH <B>List<TD $strLegendColorInfo>Info</TR>
<TR><TD> $strFontTH <B>Read Properties<TD $strLegendColorLow>Low</TR>
<TR><TD> $strFontTH <B>Read Object<TD $strLegendColorLow>Low</TR>
<TR><TD> $strFontTH <B>Read Permissions<TD $strLegendColorLow>Low</TR>
<TR><TD> $strFontTH <B>Write Propeties<TD $strLegendColorMedium>Medium</TR>
<TR><TD> $strFontTH <B>Create Object<TD $strLegendColorWarning>Warning</TR>
<TR><TD> $strFontTH <B>Delete Object<TD $strLegendColorWarning>Warning</TR>
<TR><TD> $strFontTH <B>ExtendedRight<TD $strLegendColorWarning>Warning</TR>
<TR><TD> $strFontTH <B>Modify Permisions<TD $strLegendColorCritical>Critical</TR>
<TR><TD> $strFontTH <B>Full Control<TD $strLegendColorCritical>Critical</TR>

"@


##
Out-File -InputObject $strHTAText -Force -FilePath $htafileout
}
#==========================================================================
# Function		: CreateServicePrincipalReportHTA
# Arguments     : OU Name, Ou put HTA file
# Returns   	: n/a
# Description   : Initiates a base HTA file with Export(Save As),Print and Exit buttons.
#==========================================================================
function CreateServicePrincipalReportHTA([string]$SPN,[string]$htafileout,[string]$htmfileout,[string] $folder)
{
$strHTAText =@"
<html>
<head>
<hta:Application ID="hta"
ApplicationName="Report">
<title>Membership Report on $SPN</title>
<script type="text/vbscript">
Sub ExportToCSV()
Dim objFSO,objFile,objNewFile,oShell,oEnv
Set oShell=CreateObject("wscript.shell")
Set oEnv=oShell.Environment("System")
strTemp=oShell.ExpandEnvironmentStrings("%USERPROFILE%")
strTempFile="$htmfileout"
strOutputFolder="$folder"
strFile=SaveAs("$SPN.htm",strOutputFolder)
If strFile="" Then Exit Sub
Set objFSO=CreateObject("Scripting.FileSystemObject")
objFSO.CopyFile strTempFile,strFile, true
MsgBox "Finished exporting to " & strFile,vbOKOnly+vbInformation,"Export"
End Sub
Function SaveAs(strFile,strOutFolder)
Dim objDialog
SaveAs=InputBox("Enter the filename and path."&vbCrlf&vbCrlf&"Example: "&strOutFolder&"\CONTOSO-contoso.htm","Export",strOutFolder&"\"&strFile)
End Function
</script>
</head>
<body>
<input type="button" value="Export" onclick="ExportToCSV" tabindex="9">
<input id="print_button" type="button" value="Print" name="Print_button" class="Hide" onClick="Window.print()">
<input type="button" value="Exit" onclick=self.close name="B3" tabindex="1" class="btn">
"@
Out-File -InputObject $strHTAText -Force -FilePath $htafileout
}
#==========================================================================
# Function		: CreateHTM
# Arguments     : OU Name, Ou put HTM file
# Returns   	: n/a
# Description   : Initiates a base HTM file with Export(Save As),Print and Exit buttons.
#==========================================================================
function CreateSPNHTM([string]$SPN,[string]$htmfileout)
{
$strHTAText =@"
<html>
<head[string]$SPN
<title>Membership Report on $SPN</title>
"@
Out-File -InputObject $strHTAText -Force -FilePath $htmfileout

}
#==========================================================================
# Function		: InitiateHTM
# Arguments     : Output htm file
# Returns   	: n/a
# Description   : Wites base HTM table syntax, it appends info if the file exist
#==========================================================================
Function InitiateSPNHTM([string] $htmfileout)
{
$strHTMLText ="<TABLE BORDER=1>"
$strTHOUColor = "E5CF00"
$strTHColor = "EFAC00"
$strFont =@"
<FONT size="1" face="verdana, hevetica, arial">
"@
$strFontOU =@"
<FONT size="1" face="verdana, hevetica, arial">
"@
$strFontTH =@"
<FONT size="2" face="verdana, hevetica, arial">
"@


$strHTMLText =@"
$strHTMLText
<th bgcolor="$strTHColor">$strFontTH Account Name</font></th><th bgcolor="$strTHColor">$strFontTH Object Type</font></th><th bgcolor="$strTHColor">$strFontTH Number of Groups</font></th>
"@



Out-File -InputObject $strHTMLText -Append -FilePath $htmfileout
}
#==========================================================================
# Function		: CreateHTM
# Arguments     : OU Name, Ou put HTM file
# Returns   	: n/a
# Description   : Initiates a base HTM file with Export(Save As),Print and Exit buttons.
#==========================================================================
function CreateHTM([string]$NodeName,[string]$htmfileout)
{
$strHTAText =@"
<html>
<head>
<title>Report on $NodeName</title>
"@

Out-File -InputObject $strHTAText -Force -FilePath $htmfileout
}
#==========================================================================
# Function		: BuildTree
# Arguments     : TreeView Node
# Returns   	: TreeView Node
# Description   : Build the Tree with AD objects
#==========================================================================
Function BuildTree($treeNode)
{

      # Add all Children found as Sub Nodes to the selected TreeNode

		$strFilterOUCont = "(&(|(objectClass=organizationalUnit)(objectClass=container)))"
		$strFilterAll = "(&(name=*))"
		$srch = New-Object System.DirectoryServices.DirectorySearcher
		$srch.SizeLimit = 100
        $treeNodePath = $treeNode.name

        $treeNodePath = $treeNodePath.Replace("/", "\/")

		$srch.SearchRoot = "LDAP://$global:strDC/"+$treeNodePath
		If ($rdbBrowseAll.IsChecked -eq $true)
		{
		$srch.Filter = $strFilterAll

		}
		else
		{
 		$srch.Filter = $strFilterOUCont
		}
		$srch.SearchScope = "OneLevel"
		foreach ($res in $srch.FindAll())
		{
			$oOU = $res.GetDirectoryEntry()
			If ($oOU.name -ne $null)
			{
				$TN = New-Object System.Windows.Forms.TreeNode
				$TN.Name = $oOU.distinguishedName
				$TN.Text = $oOU.name
				$TN.tag = "NotEnumerated"
				$treeNode.Nodes.Add($TN)
			}
		}
		$treeNode.tag = "Enumerated"

}
#==========================================================================
# Function		: GetADPartitions
# Arguments     : domain name
# Returns   	: N/A
# Description   : Returns AD Partitions
#==========================================================================
function GetADPartitions {
Param($strDomain)
	$ADPartlist= @{"domain" = $strDomain}
	$objDomain = [ADSI]"LDAP://$strDomain"
	[string]$strDomainObjectCateory = $objDomain.objectCategory
	[array] $dnSplit = $strDomainObjectCateory.split(",")
	$intSplit = ($dnSplit).count -1
	$strConfig = ""
	for ($i=$intSplit;$i -ge 0; $i-- )
	{
	 If($dnSplit[$i] -match "CN=Configuration")
	 {
	  	$intConfig = $i
	 	$strDomainConfig = $dnSplit[$i]
	 }
	 If($i -gt $intConfig)
	 {
	 	If ($strConfig.Length -eq 0)
	 	{
	 	$strConfig = $dnSplit[$i]
	 	}
	 	else
	 	{
	 	$strConfig = $dnSplit[$i] + "," + $strConfig
	 	}
	 }
	}
	$strDomainConfig = $strDomainConfig + "," + $strConfig
	$strDNSchema = "LDAP://CN=Enterprise Schema,CN=Partitions," + $strDomainConfig
	$ojbSchema = [ADSI]$strDNSchema

	$ADPartlist.Add("config",$strDomainConfig)
	$ADPartlist.Add("schema",$ojbSchema.nCName)

$i = $null
Remove-Variable -Name "i"

return $ADPartlist
}
#==========================================================================
# Function		: Select-File
# Arguments     : n/a
# Returns   	: folder path
# Description   : Dialogbox for selecting a file
#==========================================================================
function Select-File
{
    param (
        [System.String]$Title = "Select Template File",
        [System.String]$InitialDirectory = $CurrentFSPath,
        [System.String]$Filter = "All Files(*.csv)|*.csv"
    )

    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = $filter
    $dialog.InitialDirectory = $initialDirectory
    $dialog.ShowHelp = $true
    $dialog.Title = $title
    $result = $dialog.ShowDialog($owner)

    if ($result -eq "OK")
    {
        return $dialog.FileName
    }
    else
    {
        return ""

    }
}
#==========================================================================
# Function		: Select-Folder
# Arguments     : n/a
# Returns   	: folder path
# Description   : Dialogbox for selecting a folder
#==========================================================================
function Select-Folder($message='Select a folder', $path = 0) {
    $object = New-Object -comObject Shell.Application

    $folder = $object.BrowseForFolder(0, $message, 0, $path)
    if ($folder -ne $null) {
        $folder.self.Path
    }
}
#==========================================================================
# Function		: Get-Perm
# Arguments     : List of OU Path
# Returns   	: All Permissions on a speficied object
# Description   : Enumerates all access control entries on a speficied object
#==========================================================================
Function Get-Perm{
Param([System.Collections.ArrayList]$ALOUdn,[string]$DomainNetbiosName,[boolean]$SkipDefaultPerm,[boolean]$FilterEna,[boolean]$bolGetOwnerEna,[boolean]$bolCSVOnly,[boolean]$bolRepMeta, [boolean]$bolACLsize,[boolean]$bolEffectiveR,[boolean] $bolGetOUProtected,[boolean] $bolGUIDtoText)
$SDResult = $false
$bolCompare = $false
$bolACLExist = $true
$global:strOwner = ""
$strACLSize = ""
$bolOUProtected = $false
$aclcount = 0

If ($bolCSV)
{
	If ((Test-Path $strFileCSV) -eq $true)
	{
	Remove-Item $strFileCSV
	}
}

$count = 0
$i = 0
if ($PSVersionTable.PSVersion -ne "2.0")
{
    $intTot = 0
    #calculate percentage
    $intTot = $ALOUdn.count
    if ($intTot -gt 0)
    {
    LoadProgressBar

    }
}

while($count -le $ALOUdn.count -1)
{
$bolACLExist = $true

if ($PSVersionTable.PSVersion -ne "2.0")
{
    $i++
    [int]$pct = ($i/$intTot)*100
    #Update the progress bar

    while(($global:ProgressBarWindow.Window.IsInitialized -eq $null) -and ($intLoop -lt 20))
    {
                Start-Sleep -Milliseconds 1
                $cc++
    }
    if ($global:ProgressBarWindow.Window.IsInitialized -eq $true)
    {
        Update-ProgressBar "Currently scanning $i of $intTot objects" $pct
    }

}


    $sd =  New-Object System.Collections.ArrayList
    $GetOwnerEna = $bolGetOwnerEna
    $ADObjDN = $($ALOUdn[$count])

    if ($ADObjDN -match "/")
    {
        if ($rdbOneLevel.IsChecked -eq $false)
        {

            if ($ADObjDN -match "/")
            {
                $ADObjDN = $ADObjDN.Replace("/", "\/")
            }
            else
            {
                $ADObjDN = $ADObjDN.Replace("/", "\\\/")
            }
         }
         else
         {
          if($count -lt $ALOUdn.count -1)
          {

            if ($ADObjDN -match "/")
            {

                $ADObjDN = $ADObjDN.Replace("/", "\/")
            }
            else
            {
                $ADObjDN = $ADObjDN.Replace("/", "\\\/")
            }
          }
         }
     }

	$DSobject = [adsi]("LDAP://$global:strDC/$ADObjDN")

    $strObjectClass = $($DSobject.psbase.Properties.Item("objectClass"))[$($DSobject.psbase.Properties.Item("objectClass")).count-1]

    &{#Try

        if ($rdbDACL.IsChecked)
        {
            $global:secd = $DSobject.psbase.get_objectSecurity().getAccessRules($true, $chkInheritedPerm.IsChecked, [System.Security.Principal.NTAccount])
        }
        else
        {

            if ($chkInheritedPerm.IsChecked)
            {
                $global:secd = (Get-Acl -Path "AD:\$ADObjDN"  -Audit).Audit
            }
            else
            {
                $global:secd = (Get-Acl -Path "AD:\$ADObjDN"  -Audit).Audit | where{$_.IsInherited -eq $false}
            }
        }
    }

    Trap [SystemException]
    {
        $global:observableCollection.Insert(0,(LogMessage -strMessage "Failed to translate identity:$ADObjDN" -strType "Error" -DateStamp ))
        $global:secd = $DSobject.psbase.get_objectSecurity().getAccessRules($true, $chkInheritedPerm.IsChecked, [System.Security.Principal.SecurityIdentifier])
        Continue
    }

    $sd.clear()
    if($global:secd -ne $null){
        $(ConvertTo-ObjectArrayListFromPsCustomObject  $global:secd)| %{[void]$sd.add($_)}
    }
    If ($GetOwnerEna -eq $true)
    {

        &{#Try
            $global:strOwner = $DSobject.psbase.get_objectSecurity().getOwner([System.Security.Principal.NTAccount])
        }

        Trap [SystemException]
        {
            $global:observableCollection.Insert(0,(LogMessage -strMessage "Failed to translate owner identity:$ADObjDN" -strType "Error" -DateStamp ))
            $global:strOwner = $DSobject.psbase.get_objectSecurity().getOwner([System.Security.Principal.SecurityIdentifier])
            Continue
        }


        $newSdOwnerObject = New-Object psObject | `
        Add-Member NoteProperty IdentityReference $global:strOwner -PassThru |`
        Add-Member NoteProperty ActiveDirectoryRights "Modify permissions" -PassThru |`
        Add-Member NoteProperty InheritanceType "None" -PassThru |`
        Add-Member NoteProperty ObjectType  "None" -PassThru |`
        Add-Member NoteProperty ObjectFlags "None" -PassThru |`
        Add-Member NoteProperty AccessControlType "Owner" -PassThru |`
        Add-Member NoteProperty IsInherited "False" -PassThru |`
        Add-Member NoteProperty InheritanceFlags "None" -PassThru |`
        Add-Member NoteProperty InheritedObjectType "None" -PassThru |`
        Add-Member NoteProperty PropagationFlags "None"  -PassThru

        [void]$sd.insert(0,$newSdOwnerObject)

    }
 	If ($SkipDefaultPerm)
	{
        If ($GetOwnerEna -eq $false)
            {

            &{#Try
                $global:strOwner = $DSobject.psbase.get_objectSecurity().getOwner([System.Security.Principal.NTAccount])
            }

            Trap [SystemException]
            {
                $global:observableCollection.Insert(0,(LogMessage -strMessage "Failed to translate owner identity:$ADObjDN" -strType "Error" -DateStamp ))
                $global:strOwner = $DSobject.psbase.get_objectSecurity().getOwner([System.Security.Principal.SecurityIdentifier])
                Continue
            }
        }
        $objNodeDefSD = Get-ADSchemaClass $strObjectClass
    }
    if ($bolACLsize -eq $true)
    {
        $strACLSize = $DSobject.psbase.get_objectSecurity().GetSecurityDescriptorBinaryForm().length
    }
    if ($bolGetOUProtected -eq $true)
    {
        $bolOUProtected = $DSobject.psbase.get_objectSecurity().areaccessrulesprotected
    }
    if ($bolRepMeta -eq $true)
    {

        $AclChange = $(GetACLMeta  $global:strDC $ADObjDN)
        $objLastChange = $AclChange.split(";")[0]
        $strOrigInvocationID = $AclChange.split(";")[1]
        $strOrigUSN = $AclChange.split(";")[2]
    }


    If (($FilterEna -eq $true) -and ($bolEffectiveR -eq $false))
    {
        If ($chkBoxType.IsChecked)
        {
            if ($combAccessCtrl.SelectedIndex -gt -1)
            {
            $sd = @($sd | ?{$_.AccessControlType -eq $combAccessCtrl.SelectedItem})
            }
        }
        If ($chkBoxObject.IsChecked)
        {
            if ($combObjectFilter.SelectedIndex -gt -1)
            {

                $sd = @($sd | ?{($_.ObjectType -eq $global:dicNameToSchemaIDGUIDs.Item($combObjectFilter.SelectedItem)) -or ($_.InheritedObjectType -eq $global:dicNameToSchemaIDGUIDs.Item($combObjectFilter.SelectedItem))})
            }
        }
        If ($chkBoxTrustee.IsChecked)
        {
            if ($txtFilterTrustee.Text.Length -gt 0)
            {

            $sd = @($sd | ?{$_.IdentityReference -like $txtFilterTrustee.Text})

            }
        }

    }


    if ($bolEffectiveR -eq $true)
    {

            if ($global:tokens.count -gt 0)
            {


                $indexet = 0
                $sdtemp2 =  New-Object System.Collections.ArrayList

                if ($global:strPrincipalDN -eq $ADObjDN)
                {
                        $sdtemp = ""
                        $sdtemp = $sd | ?{$_.IdentityReference -eq "NT AUTHORITY\SELF"}
                        if($sdtemp)
                        {
                            $sdtemp2.Add( $sdtemp)
                        }
                }
                foreach ($tok in $global:tokens)
	            {

                        $sdtemp = ""
                        $sdtemp = $sd | ?{$_.IdentityReference -eq $tok}
                        if($sdtemp)
                        {
                            $sdtemp2.Add( $sdtemp)
                        }


                }
                 $sd = $sdtemp2
            }

    }
    $intSDCount =  $sd.count

    if (!($sd -eq $null))
    {



		$index=0
		$permcount = 0

    if ($intSDCount -gt 0)
    {

		while($index -le $sd.count -1)
		{

				if(($SkipDefaultPerm) -and (Check-PermDef $objNodeDefSD $sd[$index].IdentityReference $sd[$index].ActiveDirectoryRights $sd[$index].InheritanceType $sd[$index].ObjectType $sd[$index].InheritedObjectType $sd[$index].ObjectFlags $sd[$index].AccessControlType $sd[$index].IsInherited $sd[$index].InheritanceFlags $sd[$index].PropagationFlags))
				{
				}
				else
				{
					If ($bolCSV -or $bolCSVOnly)
					{

				 		WritePermCSV $sd[$index] $DSobject.distinguishedName.toString() $strFileCSV $bolRepMeta $objLastChange $strOrigInvocationID $strOrigUSN

				 	}# End If
                    If (!($bolCSVOnly))
                    {
					    If ($strColorTemp -eq "1")
					    {
						    $strColorTemp = "2"
					    }# End If
					    else
					    {
						    $strColorTemp = "1"
					    }# End If
				 	    if ($permcount -eq 0)
				 	    {

				 		    WriteHTM $bolACLExist $sd[$index] $DSobject.distinguishedName.toString() $true $strColorTemp $strFileHTA $bolCompare $FilterEna $bolRepMeta $objLastChange $bolACLsize $strACLSize $bolGetOUProtected $bolOUProtected $chkBoxEffectiveRightsColor.IsChecked $bolGUIDtoText

				 	    }
				 	    else
				 	    {

				 		    WriteHTM $bolACLExist $sd[$index] $DSobject.distinguishedName.toString() $false $strColorTemp $strFileHTA $bolCompare $FilterEna $bolRepMeta $objLastChange $bolACLsize $strACLSize $bolGetOUProtected $bolOUProtected $chkBoxEffectiveRightsColor.IsChecked $bolGUIDtoText

				 	    }# End If
                    }
                    $aclcount++
					$permcount++
				}# End If
				$index++
		}# End while

    }
    else
    {
        if(($SkipDefaultPerm) -and (Check-PermDef $objNodeDefSD $sd.IdentityReference $sd.ActiveDirectoryRights $sd.InheritanceType $sd.ObjectType $sd.InheritedObjectType $sd.ObjectFlags $sd.AccessControlType $sd.IsInherited $sd.InheritanceFlags $sd.PropagationFlags))
		{

		}
		else
		{

            If (!($bolCSVOnly))
            {
			    If ($strColorTemp -eq "1")
			    {
			    $strColorTemp = "2"
			    }
			    else
			    {
			    $strColorTemp = "1"
			    }
		 	    if ($permcount -eq 0)
		 	    {
		 		    WriteHTM $bolACLExist $sd $DSobject.distinguishedName.toString() $true $strColorTemp $strFileHTA $bolCompare $FilterEna $bolRepMeta $objLastChange $bolACLsize $strACLSize $bolGetOUProtected $bolOUProtected $chkBoxEffectiveRightsColor.IsChecked $bolGUIDtoText


		 	    }
		 	    else
		 	    {
                    $GetOwnerEna = $false
                    WriteHTM $bolACLExist $sd $DSobject.distinguishedName.toString() $false $strColorTemp $strFileHTA $bolCompare $FilterEna $bolRepMeta $objLastChange $bolACLsize $strACLSize $bolGetOUProtected $bolOUProtected $chkBoxEffectiveRightsColor.IsChecked $bolGUIDtoText
                                        $aclcount++
		 	    }
            }

            $permcount++
        }#End if Check-PermDef

    }#End if array

    If (!($bolCSVOnly))
    {
    $bolACLExist = $false
        if (($permcount -eq 0) -and ($index -gt 0))
        {

	    WriteHTM $bolACLExist $sd $DSobject.distinguishedName.toString() $true "1" $strFileHTA $bolCompare $FilterEna $bolRepMeta $objLastChange $bolACLsize $strACLSize $bolGetOUProtected $bolOUProtected $chkBoxEffectiveRightsColor.IsChecked $bolGUIDtoText
        $aclcount++
        }# End If
        }
        else #if isNull
        {
            WriteHTM $bolACLExist $sd $DSobject.distinguishedName.toString() $true "1" $strFileHTA $bolCompare $FilterEna $bolRepMeta $objLastChange $bolACLsize $strACLSize $bolGetOUProtected $bolOUProtected $chkBoxEffectiveRightsColor.IsChecked $bolGUIDtoText

        }# End if isNull
    }
	$count++
}# End while


    if (($count -gt 0))
    {
if ($aclcount -eq 0)
{
    $global:observableCollection.Insert(0,(LogMessage -strMessage "No Permissions found!" -strType "Error" -DateStamp ))
    $global:ProgressBarWindow.Window.Dispatcher.invoke([action]{$global:ProgressBarWindow.Window.Close()},"Normal")
    $ProgressBarWindow = $null
    Remove-Variable -Name "ProgressBarWindow" -Scope Global
}
else
{
if ($PSVersionTable.PSVersion -ne "2.0")
{

        $global:ProgressBarWindow.Window.Dispatcher.invoke([action]{$global:ProgressBarWindow.Window.Close()},"Normal")
        #Remove-Variable -Name "ProgressBarWindow" -Scope Global
}
        if ($bolCSVOnly)
        {

           $global:observableCollection.Insert(0,(LogMessage -strMessage "Report saved in $strFileCSV" -strType "Warning" -DateStamp ))
        }
        else
        {
	        Invoke-Item $strFileHTA
        }

    }# End If
}
else
{
    $global:observableCollection.Insert(0,(LogMessage -strMessage "No objects found!" -strType "Error" -DateStamp ))
}
$i = $null
Remove-Variable -Name "i"
$secd = $null
Remove-Variable -Name "secd" -Scope Global
return $SDResult

}

#==========================================================================
# Function		: Get-PermCompare
# Arguments     : OU Path
# Returns   	: N/A
# Description   : Compare Permissions on node with permissions in CSV file
#==========================================================================
Function Get-PermCompare{
Param([System.Collections.ArrayList]$ALOUdn,[boolean]$SkipDefaultPerm,[boolean]$bolReplMeta,[boolean]$bolGetOwnerEna,[boolean]$bolGetOUProtected,[boolean]$bolACLsize,[boolean] $bolGUIDtoText)
$Error
&{#Try
$arrFilecheck = New-Object System.Collections.ArrayList
$arrOUList = New-Object System.Collections.ArrayList
$bolCompare = $true
$bolCompareDelegation = $false
$bolFilter = $false
$bolOUPRotected = $false
$strACLSize = ""
$bolAClMeta = $false
$strOwner = ""
$count = 0
$aclcount = 0

if ($chkBoxTemplateNodes.IsChecked -eq $true)
{
    $index = 0
    while($index -le $HistACLs.count -1)
    {
	    $txtPerm = $HistACLs[$index].split(";")
        if($txtPerm.count -gt $global:intColCount)
        {
            $global:intDiffCol = ($txtPerm.count ) - $global:intColCount
            $countCol = 0
            $strOUcol = ""
            while($countCol -le $global:intDiffCol)
            {
                if ($countCol -eq 0)
                {
                    $strOUcol =$txtPerm[$countCol]
                }
                else
                {
                   $strOUcol =$strOUcol+";"+$txtPerm[$countCol]

                }
                $countCol++

            }
            $arrOUList.Add($strOUcol)
        }
        else
        {
        $arrOUList.Add($txtPerm[0])
        }


        $index++
    }
    $arrOUListUnique = $arrOUList | select -Unique
    $ALOUdn = @($arrOUListUnique)
}
If ($bolReplMeta -eq $true)
{
    if($HistACLs[0].split(";").count -ge $global:intColCount)
    {
        If ($HistACLs[0].split(";")[$HistACLs[0].split(";").count - 2].length -gt 1)
        {
        $bolAClMeta = $true
        }
    }
}



$i = 0
if ($PSVersionTable.PSVersion -ne "2.0")
{
    $intTot = 0
    #calculate percentage
    $intTot = $ALOUdn.count
    if ($intTot -gt 0)
    {
    LoadProgressBar

    }
}

while($count -le $ALOUdn.count -1)
{

    if ($PSVersionTable.PSVersion -ne "2.0")
    {
        $i++
        [int]$pct = ($i/$intTot)*100
        #Update the progress bar
        while(($global:ProgressBarWindow.Window.IsInitialized -eq $null) -and ($intLoop -lt 20))
        {
                    Start-Sleep -Milliseconds 1
                    $cc++
        }
        if ($global:ProgressBarWindow.Window.IsInitialized -eq $true)
        {
            Update-ProgressBar "Currently scanning $i of $intTot objects" $pct
        }

    }

    $SDUsnCheck = $false
    $OUMatchResultOverall = $false
    $bolAddedACL = $false
    $bolMissingACL = $false
    $OUdn = $($ALOUdn[$count])

    #Save the orginal name for AD for compare
    $OUdnorgDN = $OUdn
    If ($bolReplMeta -eq $true)
    {

        $AclChange = $(GetACLMeta  $global:strDC $OUdn)
        $objLastChange = $AclChange.split(";")[0]
        $strOrigInvocationID = $AclChange.split(";")[1]
        $strOrigUSN = $AclChange.split(";")[2]
    }

    if ($OUdn -match "/")
    {
        if ($rdbOneLevel.IsChecked -eq $false)
        {

            if ($OUdn -match "/")
            {
                $OUdn = $OUdn.Replace("/", "\/")
            }
            else
            {
                $OUdn = $OUdn.Replace("/", "\\\/")
            }
        }
        else
        {
            if($count -lt $ALOUdn.count -1)
            {

                if ($OUdn -match "/")
                {

                    $OUdn = $OUdn.Replace("/", "\/")
                }
                else
                {
                    $OUdn = $OUdn.Replace("/", "\\\/")
                }
            }
         }
    }


    #Counter used for fitlerout Nodes with only defaultpermissions configured
    $intAclOccurence = 0

    $sd =  New-Object System.Collections.ArrayList

    $GetOwnerEna = $bolGetOwnerEna
	$DSobject = [adsi]("LDAP://$global:strDC/$OUdn")

    #Testing ObjectClass reporting
    $strObjectClass = $($DSobject.psbase.Properties.Item("objectClass"))[$($DSobject.psbase.Properties.Item("objectClass")).count-1]


    if ($bolACLsize -eq $true)
    {
        $strACLSize = $DSobject.psbase.get_objectSecurity().GetSecurityDescriptorBinaryForm().length
    }

    if ($bolGetOUProtected -eq $true)
    {

        $bolOUProtected = $DSobject.psbase.get_objectSecurity().areaccessrulesprotected
    }



    &{#Try
        $global:secd = $DSobject.psbase.get_objectSecurity().getAccessRules($true, $chkInheritedPerm.IsChecked, [System.Security.Principal.NTAccount])
    }

    Trap [SystemException]
    {

        $global:observableCollection.Insert(0,(LogMessage -strMessage "Failed to translate identity:$OUdn" -strType "Error" -DateStamp ))
        $global:secd = $DSobject.psbase.get_objectSecurity().getAccessRules($true, $chkInheritedPerm.IsChecked, [System.Security.Principal.SecurityIdentifier])
        Continue
    }

    $sd.clear()
    if($global:secd -ne $null){
        $(ConvertTo-ObjectArrayListFromPsCustomObject  $global:secd)| %{[void]$sd.add($_)}
    }
    If ($GetOwnerEna -eq $true)
    {

        $strOwner = $DSobject.psbase.get_objectSecurity().getOwner([System.Security.Principal.NTAccount])
        &{#Try
            $global:strOwner = $DSobject.psbase.get_objectSecurity().getOwner([System.Security.Principal.NTAccount])
        }

        Trap [SystemException]
        {
            $global:observableCollection.Insert(0,(LogMessage -strMessage "Failed to translate owner identity:$ADObjDN" -strType "Error" -DateStamp ))
            $global:strOwner = $DSobject.psbase.get_objectSecurity().getOwner([System.Security.Principal.SecurityIdentifier])
            Continue
        }
        $newSdOwnerObject = New-Object psObject | `
        Add-Member NoteProperty IdentityReference $global:strOwner -PassThru |`
        Add-Member NoteProperty ActiveDirectoryRights "Modify permissions" -PassThru |`
        Add-Member NoteProperty InheritanceType "None" -PassThru |`
        Add-Member NoteProperty ObjectType  "None" -PassThru |`
        Add-Member NoteProperty ObjectFlags "None" -PassThru |`
        Add-Member NoteProperty AccessControlType "Owner" -PassThru |`
        Add-Member NoteProperty IsInherited "False" -PassThru |`
        Add-Member NoteProperty InheritanceFlags "None" -PassThru |`
        Add-Member NoteProperty InheritedObjectType "None" -PassThru |`
        Add-Member NoteProperty PropagationFlags "None"  -PassThru
        [void]$sd.insert(0,$newSdOwnerObject)

    }

$rar = @($($sd | select -Property *))


    $index = 0
    $SDResult = $false
    $OUMatchResult = $false



    If ($SkipDefaultPerm)
	{
        If ($GetOwnerEna -eq $false)
            {

            &{#Try
                $global:strOwner = $DSobject.psbase.get_objectSecurity().getOwner([System.Security.Principal.NTAccount])
            }

            Trap [SystemException]
            {
                $global:observableCollection.Insert(0,(LogMessage -strMessage "Failed to translate owner identity:$ADObjDN" -strType "Error" -DateStamp ))
                $global:strOwner = $DSobject.psbase.get_objectSecurity().getOwner([System.Security.Principal.SecurityIdentifier])
                Continue
            }
        }
        $objNodeDefSD = Get-ADSchemaClass $strObjectClass
    }

	foreach($sdObject in $rar)
	{

           if(($SkipDefaultPerm) -and (Check-PermDef $objNodeDefSD $sdObject.IdentityReference $sdObject.ActiveDirectoryRights $sdObject.InheritanceType $sdObject.ObjectType $sdObject.InheritedObjectType $sdObject.ObjectFlags $sdObject.AccessControlType $sdObject.IsInherited $sdObject.InheritanceFlags $sdObject.PropagationFlags))
   			{
        }
        else
        {


		$index = 0
		$SDResult = $false
        $OUMatchResult = $false
            $aclcount++
            $newSdObject = New-Object psObject | `
            Add-Member NoteProperty IdentityReference $sdObject.IdentityReference.value -PassThru |`
            Add-Member NoteProperty ActiveDirectoryRights $sdObject.ActiveDirectoryRights -PassThru |`
            Add-Member NoteProperty InheritanceType $sdObject.InheritanceType -PassThru |`
            Add-Member NoteProperty ObjectType  $sdObject.ObjectType -PassThru |`
            Add-Member NoteProperty ObjectFlags $sdObject.ObjectFlags -PassThru |`
            Add-Member NoteProperty AccessControlType $sdObject.AccessControlType -PassThru |`
            Add-Member NoteProperty IsInherited $sdObject.IsInherited -PassThru |`
            Add-Member NoteProperty InheritanceFlags $sdObject.InheritanceFlags -PassThru |`
            Add-Member NoteProperty InheritedObjectType $sdObject.InheritedObjectType -PassThru |`
            Add-Member NoteProperty PropagationFlags $sdObject.PropagationFlags  -PassThru|`
            Add-Member NoteProperty Color "Match"  -PassThru

            if ($SDUsnCheck -eq $true)
            {
            $SDResult = $true
            }
            else
            {
		    while($index -le $HistACLs.count -1)
		    {
			    $txtPerm = $HistACLs[$index].split(";")
                if($txtPerm.count -gt $global:intColCount)
                {
                    $global:intDiffCol = ($txtPerm.count ) - $global:intColCount
                    $countCol = 0
                    $strOUcol = ""
                    while($countCol -le $global:intDiffCol)
                    {
                        if ($countCol -eq 0)
                        {
                            $strOUcol =$txtPerm[$countCol]
                        }
                        else
                        {
                           $strOUcol =$strOUcol+";"+$txtPerm[$countCol]

                        }
                        $countCol++

                    }

                }
                else
                {
                    $strOUcol = $txtPerm[0]
                }

			    if ($OUdnorgDN -eq $strOUcol )
			    {
                    $OUMatchResult = $true
                    $OUMatchResultOverall = $true
				    $strIdentityReference = $txtPerm[1+$global:intDiffCol]
				    $strTmpActiveDirectoryRights = $txtPerm[2+$global:intDiffCol]
				    $strTmpInheritanceType = $txtPerm[3+$global:intDiffCol]
				    $strTmpObjectTypeGUID = $txtPerm[4+$global:intDiffCol]
				    $strTmpInheritedObjectTypeGUID = $txtPerm[5+$global:intDiffCol]
				    $strTmpObjectFlags = $txtPerm[6+$global:intDiffCol]
				    $strTmpAccessControlType = $txtPerm[7+$global:intDiffCol]
                    if ($strTmpAccessControlType -eq "Owner" )
                    {
                        $global:strOwnerTemplate = $strIdentityReference
                    }
				    $strTmpIsInherited = $txtPerm[8+$global:intDiffCol]
				    $strTmpInheritedFlags = $txtPerm[9+$global:intDiffCol]
				    $strTmpPropFlags = $txtPerm[10+$global:intDiffCol]

                    If (($newSdObject.IdentityReference -eq $strIdentityReference) -and ($newSdObject.ActiveDirectoryRights -eq $strTmpActiveDirectoryRights) -and ($newSdObject.AccessControlType -eq $strTmpAccessControlType) -and ($newSdObject.ObjectType -eq $strTmpObjectTypeGUID) -and ($newSdObject.InheritanceType -eq $strTmpInheritanceType) -and ($newSdObject.InheritedObjectType -eq $strTmpInheritedObjectTypeGUID))
		 		    {
					    $SDResult = $true
		 		    }

		 	    }
			    $index++
		    }# End While
        }

        if ($SDResult)
        {
                    if ($intAclOccurence -eq 0)
                    {
                        $intAclOccurence++
                        WriteHTM $false $sd $DSobject.distinguishedName.toString() $true $strColorTemp $strFileHTA $bolCompare $bolFilter $bolReplMeta $objLastChange $bolACLsize $strACLSize $bolGetOUProtected $bolOUProtected $chkBoxEffectiveRightsColor.IsChecked $bolGUIDtoText

                    }

                    WriteHTM $true $newSdObject $OUdn $false "4" $strFileHTA $bolCompare $bolFilter $bolReplMeta $objLastChange $bolACLsize $strACLSize $bolGetOUProtected $bolOUProtected $chkBoxEffectiveRightsColor.IsChecked $bolGUIDtoText

        }
		If ($OUMatchResult -And !($SDResult))
		{
                    if ($intAclOccurence -eq 0)
                    {
                        $intAclOccurence++
                        WriteHTM $false $sd $DSobject.distinguishedName.toString() $true $strColorTemp $strFileHTA $bolCompare $bolFilter $bolReplMeta $objLastChange $bolACLsize $strACLSize $bolGetOUProtected $bolOUProtected $chkBoxEffectiveRightsColor.IsChecked $bolGUIDtoText
                    }
            $bolAddedACL = $true
            $newSdObject.Color = "New"
            WriteHTM $true $newSdObject $OUdn $false "5" $strFileHTA $bolCompare $bolFilter $bolReplMeta $objLastChange $bolACLsize $strACLSize $bolGetOUProtected $bolOUProtected $chkBoxEffectiveRightsColor.IsChecked $bolGUIDtoText

         }

}


	}

If ($SDUsnCheck -eq $false)
{
$index = 0

while($index -le $HistACLs.count -1)
{

       $SDHistResult = $false
			$txtPerm = $HistACLs[$index].split(";")
            if($txtPerm.count -gt $global:intColCount)
            {
                $global:intDiffCol = ($txtPerm.count ) - $global:intColCount
                $countCol = 0
                $strOUcol = ""
                while($countCol -le $global:intDiffCol)
                {
                    if ($countCol -eq 0)
                    {
                        $strOUcol =$txtPerm[$countCol]
                    }
                    else
                    {
                        $strOUcol =$strOUcol+";"+$txtPerm[$countCol]

                    }
                    $countCol++

                }

            }
            else
            {
                $strOUcol = $txtPerm[0]
            }
			if ($OUdnorgDN -eq $strOUcol )
			{
                $OUMatchResult = $true
				$strIdentityReference = $txtPerm[1+$global:intDiffCol]
				$strTmpActiveDirectoryRights = $txtPerm[2+$global:intDiffCol]
				$strTmpInheritanceType = $txtPerm[3+$global:intDiffCol]
				$strTmpObjectTypeGUID = $txtPerm[4+$global:intDiffCol]
				$strTmpInheritedObjectTypeGUID = $txtPerm[5+$global:intDiffCol]
				$strTmpObjectFlags = $txtPerm[6+$global:intDiffCol]
				$strTmpAccessControlType = $txtPerm[7+$global:intDiffCol]
     if ($strTmpAccessControlType -eq "Owner" )
                    {

                        $global:strOwnerTemplate = $strIdentityReference
                    }
				$strTmpIsInherited = $txtPerm[8+$global:intDiffCol]
				$strTmpInheritedFlags = $txtPerm[9+$global:intDiffCol]
				$strTmpPropFlags = $txtPerm[10+$global:intDiffCol]


                $rarHistCheck = @($($sd | select -Property *))

	               foreach($sdObject in $rarHistCheck)
	               {
                        if(($SkipDefaultPerm) -and (Check-PermDef $objNodeDefSD $sdObject.IdentityReference $sdObject.ActiveDirectoryRights $sdObject.InheritanceType $sdObject.ObjectType $sdObject.InheritedObjectType $sdObject.ObjectFlags $sdObject.AccessControlType $sdObject.IsInherited $sdObject.InheritanceFlags $sdObject.PropagationFlags))
   		                    {
                        }
                        else
                        {
                            $newSdObject = New-Object psObject | `
                            Add-Member NoteProperty IdentityReference $sdObject.IdentityReference.value -PassThru |`
                            Add-Member NoteProperty ActiveDirectoryRights $sdObject.ActiveDirectoryRights -PassThru |`
                            Add-Member NoteProperty InheritanceType $sdObject.InheritanceType -PassThru |`
                            Add-Member NoteProperty ObjectType  $sdObject.ObjectType -PassThru |`
                            Add-Member NoteProperty ObjectFlags $sdObject.ObjectFlags -PassThru |`
                            Add-Member NoteProperty AccessControlType $sdObject.AccessControlType -PassThru |`
                            Add-Member NoteProperty IsInherited $sdObject.IsInherited -PassThru |`
                            Add-Member NoteProperty InheritanceFlags $sdObject.InheritanceFlags -PassThru |`
                            Add-Member NoteProperty InheritedObjectType $sdObject.InheritedObjectType -PassThru |`
                            Add-Member NoteProperty PropagationFlags $sdObject.PropagationFlags  -PassThru


                            If (($newSdObject.IdentityReference -eq $strIdentityReference) -and ($newSdObject.ActiveDirectoryRights -eq $strTmpActiveDirectoryRights) -and ($newSdObject.AccessControlType -eq $strTmpAccessControlType) -and ($newSdObject.ObjectType -eq $strTmpObjectTypeGUID) -and ($newSdObject.InheritanceType -eq $strTmpInheritanceType) -and ($newSdObject.InheritedObjectType -eq $strTmpInheritedObjectTypeGUID))
                            {
                                $SDHistResult = $true
                            }#End If $newSdObject
                        }
                    }# End foreach



                If ($OUMatchResult -And !($SDHistResult))
                {

                    $bolMissingACL = $true

                    $histSDObject = New-Object psObject | `
                    Add-Member NoteProperty IdentityReference $txtPerm[1+$global:intDiffCol] -PassThru |`
                    Add-Member NoteProperty ActiveDirectoryRights $txtPerm[2+$global:intDiffCol] -PassThru |`
                    Add-Member NoteProperty InheritanceType $txtPerm[3+$global:intDiffCol] -PassThru |`
                    Add-Member NoteProperty ObjectType  $txtPerm[4+$global:intDiffCol] -PassThru |`
                    Add-Member NoteProperty ObjectFlags $txtPerm[6+$global:intDiffCol] -PassThru |`
                    Add-Member NoteProperty AccessControlType $txtPerm[7+$global:intDiffCol] -PassThru |`
                    Add-Member NoteProperty IsInherited $txtPerm[8+$global:intDiffCol] -PassThru |`
                    Add-Member NoteProperty InheritanceFlags $txtPerm[9+$global:intDiffCol] -PassThru |`
                    Add-Member NoteProperty InheritedObjectType $txtPerm[5+$global:intDiffCol] -PassThru |`
                    Add-Member NoteProperty PropagationFlags $txtPerm[10+$global:intDiffCol] -PassThru   |`
                    Add-Member NoteProperty Color "Missing" -PassThru

                    if ($intAclOccurence -eq 0)
                    {
                        $intAclOccurence++
                        WriteHTM $false $sd $DSobject.distinguishedName.toString() $true $strColorTemp $strFileHTA $bolCompare $bolFilter $bolReplMeta $objLastChange $bolACLsize $strACLSize $bolGetOUProtected $bolOUProtected $chkBoxEffectiveRightsColor.IsChecked $bolGUIDtoText
                    }

                    WriteHTM $true $histSDObject $OUdn $false "3" $strFileHTA $bolCompare $bolFilter $bolReplMeta $objLastChange $bolACLsize $strACLSize $bolGetOUProtected $bolOUProtected $chkBoxEffectiveRightsColor.IsChecked $bolGUIDtoText
                    $histSDObject = ""
                }# End If $OUMatchResult
            }# End if $OUdn
			$index++
		}# End While
        if ($bolMissingACL -eq $true)
        {
        #Write-host "This is a object has lost a ACL $OUdnorgDN"
        }
        if ($bolAddedACL -eq $true)
        {
        #Write-host "This is a object has a new ACL $OUdnorgDN"
        }
} #End If If ($SDUsnCheck -eq $false)

If (!$OUMatchResultOverall)
{

if ($bolOUProtected -eq $true)
{

}

### Playing with reporint new ou's
if ($strobjectclass -eq "organizationalUnit")
{



}
    if($SkipDefaultPerm -or $bolCompareDelegation)
    {
        $objNodeDefSD = Get-ADSchemaClass $strObjectClass
    }
	foreach($sdObject in $rar)
	{
        if(($SkipDefaultPerm -or $bolCompareDelegation) -and (Check-PermDef $objNodeDefSD $sdObject.IdentityReference $sdObject.ActiveDirectoryRights $sdObject.InheritanceType $sdObject.ObjectType $sdObject.InheritedObjectType $sdObject.ObjectFlags $sdObject.AccessControlType $sdObject.IsInherited $sdObject.InheritanceFlags $sdObject.PropagationFlags))
        {
        }
        else
        {
            if($SkipDefaultPerm -or $bolCompareDelegation)
            {
                $strDelegationNotation = "Out of Policy"


                            If (($sdObject.IdentityReference -eq $global:strOwnerTemplate) -and ($sdObject.ActiveDirectoryRights -eq "Modify permissions") -and ($sdObject.AccessControlType -eq "Owner") -and ($sdObject.ObjectType -eq "None") -and ($sdObject.InheritanceType -eq "None") -and ($sdObject.InheritedObjectType -eq "None"))
                            {

                            }#End If $newSdObject
                            else
                            {
                                $MissingOUSdObject = New-Object psObject | `
                                Add-Member NoteProperty IdentityReference $sdObject.IdentityReference.value -PassThru |`
                                Add-Member NoteProperty ActiveDirectoryRights $sdObject.ActiveDirectoryRights -PassThru |`
                                Add-Member NoteProperty InheritanceType $sdObject.InheritanceType -PassThru |`
                                Add-Member NoteProperty ObjectType  $sdObject.ObjectType -PassThru |`
                                Add-Member NoteProperty ObjectFlags $sdObject.ObjectFlags -PassThru |`
                                Add-Member NoteProperty AccessControlType $sdObject.AccessControlType -PassThru |`
                                Add-Member NoteProperty IsInherited $sdObject.IsInherited -PassThru |`
                                Add-Member NoteProperty InheritanceFlags $sdObject.InheritanceFlags -PassThru |`
                                Add-Member NoteProperty InheritedObjectType $sdObject.InheritedObjectType -PassThru |`
                                Add-Member NoteProperty PropagationFlags $sdObject.PropagationFlags  -PassThru|`
                                Add-Member NoteProperty Color $strDelegationNotation  -PassThru

                                if ($intAclOccurence -eq 0)
                                {
                                    $intAclOccurence++
                                    WriteHTM $false $sd $DSobject.distinguishedName.toString() $true $strColorTemp $strFileHTA $bolCompare $bolFilter $bolReplMeta $objLastChange $bolACLsize $strACLSize $bolGetOUProtected $bolOUProtected $chkBoxEffectiveRightsColor.IsChecked $bolGUIDtoText
                                }

                                WriteHTM $true $MissingOUSdObject $OUdn $false "5" $strFileHTA $bolCompare $bolFilter $bolReplMeta $objLastChange $bolACLsize $strACLSize $bolGetOUProtected $bolOUProtected $chkBoxEffectiveRightsColor.IsChecked $bolGUIDtoText
                                }
            }
            else
            {
                $strDelegationNotation = "Node not in file"

            $MissingOUSdObject = New-Object psObject | `
            Add-Member NoteProperty IdentityReference $sdObject.IdentityReference.value -PassThru |`
            Add-Member NoteProperty ActiveDirectoryRights $sdObject.ActiveDirectoryRights -PassThru |`
            Add-Member NoteProperty InheritanceType $sdObject.InheritanceType -PassThru |`
            Add-Member NoteProperty ObjectType  $sdObject.ObjectType -PassThru |`
            Add-Member NoteProperty ObjectFlags $sdObject.ObjectFlags -PassThru |`
            Add-Member NoteProperty AccessControlType $sdObject.AccessControlType -PassThru |`
            Add-Member NoteProperty IsInherited $sdObject.IsInherited -PassThru |`
            Add-Member NoteProperty InheritanceFlags $sdObject.InheritanceFlags -PassThru |`
            Add-Member NoteProperty InheritedObjectType $sdObject.InheritedObjectType -PassThru |`
            Add-Member NoteProperty PropagationFlags $sdObject.PropagationFlags  -PassThru|`
            Add-Member NoteProperty Color $strDelegationNotation  -PassThru

            if ($intAclOccurence -eq 0)
            {
                $intAclOccurence++
                WriteHTM $false $sd $DSobject.distinguishedName.toString() $true $strColorTemp $strFileHTA $bolCompare $bolFilter $bolReplMeta $objLastChange $bolACLsize $strACLSize $bolGetOUProtected $bolOUProtected $chkBoxEffectiveRightsColor.IsChecked $bolGUIDtoText
            }

            WriteHTM $true $MissingOUSdObject $OUdn $false "5" $strFileHTA $bolCompare $bolFilter $bolReplMeta $objLastChange $bolACLsize $strACLSize $bolGetOUProtected $bolOUProtected $chkBoxEffectiveRightsColor.IsChecked $bolGUIDtoText
            }
        }
    }
  }
  $count++
}# End While

    if (($count -gt 0))
    {
        if ($PSVersionTable.PSVersion -ne "2.0")
        {

                $global:ProgressBarWindow.Window.Dispatcher.invoke([action]{$global:ProgressBarWindow.Window.Close()},"Normal")
        }

        if ($aclcount -eq 0)
        {
        [System.Windows.Forms.MessageBox]::Show("No Permissions found!" , "Status")
        }
        else
        {
                if ($bolCSVOnly)
                {

                   [System.Windows.Forms.MessageBox]::Show("Done!" , "Status")
                }
                else
                {
	                Invoke-Item $strFileHTA
                }

            }# End If
        }
else
{
[System.Windows.Forms.MessageBox]::Show("No objects found!" , "Status")


}
}# End Try
 Trap [SystemException]
 {
#

Invoke-Item $strFileHTA
;Continue
 }

 $histSDObject = ""
 $sdObject = ""
 $arrObjClassSplit = ""
 $MissingOUSdObject = ""
 $newSdObject = ""
 $DSobject = ""
 $global:strOwner = ""
 $HistACLs = ""
 $txtPerm = ""
 $objNodeDefSD = ""
 $MissingOUOwnerObject = ""


$secd = $null
Remove-Variable -Name "secd" -Scope Global
}

#==========================================================================
# Function		:  ConvertCSVtoHTM
# Arguments     : Fle Path
# Returns   	: N/A
# Description   : Convert CSV file to HTM Output
#==========================================================================
Function ConvertCSVtoHTM{
Param($CSVInput,[boolean] $bolGUIDtoText)
$bolRepMeta = $false
If(Test-Path $CSVInput)
{

    $fileName = $(Get-ChildItem $CSVInput).BaseName
	$strFileHTA = $env:temp + "\ACLHTML.hta"
	$strFileHTM = $env:temp + "\"+"$fileName"+".htm"

    $fs = [System.IO.File]::OpenText($CSVInput)
    while ($fs.Peek() -ne -1)
    {
	    $line = $fs.ReadLine();
		$arrline = $line.split(";")
        #Check if CSV contains the least number of columns for metadata info
        if($arrline.count -ge $global:intColCount)
        {
            If ($arrline[$arrline.count - 2].length -gt 1)
            {
             $bolRepMeta = $true
             }
         }
     }
    $fs.close()

    CreateHTA $fileName $strFileHTA $strFileHTM $CurrentFSPath
    CreateHTM $fileName $strFileHTM
    InitiateHTM $strFileHTA $bolRepMeta $false $false
	InitiateHTM $strFileHTM $bolRepMeta $false $false

    $tmpOU = ""
    $fs = [System.IO.File]::OpenText($CSVInput)
    while ($fs.Peek() -ne -1)
    {
	    $line = $fs.ReadLine();

		$txtPerm = $line.split(";")

        if($txtPerm.count -gt $global:intColCount)
        {
            $global:intDiffCol = ($txtPerm.count ) - $global:intColCount
            $count = 0
            $strOUcol = ""
            while($count -le $global:intDiffCol)
            {
                if ($count -eq 0)
                {
                    $strOUcol =$txtPerm[$count]
                }
                else
                {
                    $strOUcol =$strOUcol+";"+$txtPerm[$count]

                }
                $count++

            }

        }
        else
        {
            $strOUcol = $txtPerm[0]
        }



    If ($bolRepMeta -eq $true)
    {

		    $strOU = $strOUcol
		    $strOU = ($strOU.Replace($OldDomDN,$strDomainDN))
		    $strTrustee = $txtPerm[1+$global:intDiffCol]
		    $strRights = $txtPerm[2+$global:intDiffCol]
		    $strInheritanceType = $txtPerm[3+$global:intDiffCol]
		    $strObjectTypeGUID = $txtPerm[4+$global:intDiffCol]
		    $strInheritedObjectTypeGUID = $txtPerm[5+$global:intDiffCol]
		    $strObjectFlags = $txtPerm[6+$global:intDiffCol]
		    $strAccessControlType = $txtPerm[7+$global:intDiffCol]
		    $strIsInherited = $txtPerm[8+$global:intDiffCol]
		    $strInheritedFlags = $txtPerm[9+$global:intDiffCol]
		    $strPropFlags = $txtPerm[10+$global:intDiffCol]
            $strTmpACLDate = $txtPerm[11+$global:intDiffCol]

    }
    else
    {

		    $strOU = $strOUcol
		    $strOU = ($strOU.Replace($OldDomDN,$strDomainDN))
		    $strTrustee = $txtPerm[1+$global:intDiffCol]
		    $strRights = $txtPerm[2+$global:intDiffCol]
		    $strInheritanceType = $txtPerm[3+$global:intDiffCol]
		    $strObjectTypeGUID = $txtPerm[4+$global:intDiffCol]
		    $strInheritedObjectTypeGUID = $txtPerm[5+$global:intDiffCol]
		    $strObjectFlags = $txtPerm[6+$global:intDiffCol]
		    $strAccessControlType = $txtPerm[7+$global:intDiffCol]
		    $strIsInherited = $txtPerm[8+$global:intDiffCol]
		    $strInheritedFlags = $txtPerm[9+$global:intDiffCol]
		    $strPropFlags = $txtPerm[10+$global:intDiffCol]

    }
            $txtSdObject = New-Object psObject | `
            Add-Member NoteProperty IdentityReference $strTrustee -PassThru |`
            Add-Member NoteProperty ActiveDirectoryRights $strRights -PassThru |`
            Add-Member NoteProperty InheritanceType $strInheritanceType -PassThru |`
            Add-Member NoteProperty ObjectType  $strObjectTypeGUID -PassThru |`
            Add-Member NoteProperty ObjectFlags $strObjectFlags -PassThru |`
            Add-Member NoteProperty AccessControlType $strAccessControlType -PassThru |`
            Add-Member NoteProperty IsInherited $strIsInherited -PassThru |`
            Add-Member NoteProperty InheritanceFlags $strInheritedFlags -PassThru |`
            Add-Member NoteProperty InheritedObjectType $strInheritedObjectTypeGUID -PassThru |`
            Add-Member NoteProperty PropagationFlags $strPropFlags -PassThru



	    If ($strColorTemp -eq "1")
	    {
		    $strColorTemp = "2"
	    }# End If
	    else
	    {
		    $strColorTemp = "1"
	    }# End If
        if ($tmpOU -ne $strOU)
        {


            WriteHTM $true $txtSdObject $strOU $true $strColorTemp $strFileHTA $false $false $bolRepMeta $strTmpACLDate $false $strACLSize $false $false $chkBoxEffectiveRightsColor.IsChecked $bolGUIDtoText


            $tmpOU = $strOU
    }
    else
    {

            WriteHTM $true $txtSdObject $strOU $false $strColorTemp $strFileHTA $false $false $bolRepMeta $strTmpACLDate  $false $strACLSize $false $false $chkBoxEffectiveRightsColor.IsChecked $bolGUIDtoText

    }



    }
    #Close the CSV file
    $fs.close()
    Invoke-Item $strFileHTA
}
else
{
    $global:observableCollection.Insert(0,(LogMessage -strMessage "Failed! $CSVInput does not exist!" -strType "Error" -DateStamp ))
}

}# End Function


#==========================================================================
# Function		: ImportADSettings
# Arguments     : strDN
# Returns   	: n/a
# Description   : bla bla
#==========================================================================
 function ImportADSettings
 {
Param ([string] $Template )

[void] $HistACLs.Clear()
 $fs = [System.IO.File]::OpenText($Template)
while ($fs.Peek() -ne -1)
{
    $line = $fs.ReadLine();
    [void] $HistACLs.Add($line)
}#End While

#Close the CSV file
$fs.close()


}
#==========================================================================
# Function		: New-Type
# Arguments     : C# Code, dll
# Returns   	: n/a
# Description   : Takes C# source code, and compiles it (in memory) for use in scri ...
#==========================================================================
function New-Type {
   param([string]$TypeDefinition,[string[]]$ReferencedAssemblies)

   $provider = New-Object Microsoft.CSharp.CSharpCodeProvider
   $dllName = [PsObject].Assembly.Location
   $compilerParameters = New-Object System.CodeDom.Compiler.CompilerParameters

   $assemblies = @("System.dll", $dllName)
   $compilerParameters.ReferencedAssemblies.AddRange($assemblies)
   if($ReferencedAssemblies) {
      $compilerParameters.ReferencedAssemblies.AddRange($ReferencedAssemblies)
   }

   $compilerParameters.IncludeDebugInformation = $true
   $compilerParameters.GenerateInMemory = $true

   $compilerResults = $provider.CompileAssemblyFromSource($compilerParameters, $TypeDefinition)
   if($compilerResults.Errors.Count -gt 0) {
     $compilerResults.Errors | % { Write-Error ("{0}:`t{1}" -f $_.Line,$_.ErrorText) }
   }
}
#==========================================================================
# Function		: GetACLMeta
# Arguments     : Domain Controller, AD Object DN
# Returns   	: Semi-colon separated string
# Description   : Get AD Replication Meta data LastOriginatingChange, LastOriginatingDsaInvocationID
#                  usnOriginatingChange and returns as string
#==========================================================================
Function GetACLMeta()
{
    Param($DomainController,$objDN)

    $objADObj = [ADSI]"LDAP://$DomainController/$objDN"
    $objADObj.psbase.RefreshCache("msDS-ReplAttributeMetaData")
         foreach($childMember in $objADObj.psbase.Properties.Item("msDS-ReplAttributeMetaData"))

         {
            If ($([xml]$childMember).DS_REPL_ATTR_META_DATA.pszAttributeName -eq "nTSecurityDescriptor")
            {
            $strLastChangeDate = $([xml]$childMember).DS_REPL_ATTR_META_DATA.ftimeLastOriginatingChange
            $strInvocationID = $([xml]$childMember).DS_REPL_ATTR_META_DATA.uuidLastOriginatingDsaInvocationID
            $strOriginatingChange = $([xml]$childMember).DS_REPL_ATTR_META_DATA.usnOriginatingChange
            }
         }

if ($strLastChangeDate -eq $nul)
{
    $ACLdate = $(get-date "1601-01-01" -UFormat "%Y-%m-%d %H:%M:%S")
    $strInvocationID = "00000000-0000-0000-0000-000000000000"
    $strOriginatingChange = "000000"
}
else
{
$ACLdate = $(get-date $strLastChangeDate -UFormat "%Y-%m-%d %H:%M:%S")
}
  return "$ACLdate;$strInvocationID;$strOriginatingChange"
}

#==========================================================================
# Function		: GetACLSize
# Arguments     :
# Returns   	: Lenght of Security Descriptor
# Description   : Return the size of the Security Descriptor in bytes
#==========================================================================
Function GetACLSize()
{
$DSobject = [adsi]("LDAP://$($ALOUdn[$count])")
    $DSobject.psbase.get_objectSecurity().GetSecurityDescriptorBinaryForm().length
}
#==========================================================================
# Function		: GetEffectiveRightSP
# Arguments     :
# Returns   	:
# Description   : Rs
#==========================================================================
Function GetEffectiveRightSP()
{
param([string] $strPrincipal,
[string] $strDomainDistinguishedName
)
$global:strEffectiveRightSP = ""
$global:strEffectiveRightAccount = ""
$global:strSPNobjectClass = ""
$global:strPrincipalDN = ""
$strPrinName = ""
$global:Creds = ""
if ($global:strPrinDomDir -eq 2)
{
    &{#Try

    $global:Creds = $host.ui.PromptForCredential("Need credentials", "Please enter your user name and password.", "", "$global:strPrinDomFlat")
    }
    Trap [SystemException]
    {
    continue
    }
    $h =  (get-process -id $global:myPID).MainWindowHandle # just one notepad must be opened!
    [SFW]::SetForegroundWindow($h)
    if($global:Creds.UserName -ne $null)
    {
        if (TestCreds $global:Creds)
        {
            $global:strPinDomDC = $(GetDomainController $global:strDomainPrinDNName $true $global:Creds)
            $global:strPrincipalDN = (GetSecPrinDN $strPrincipal $strDomainDistinguishedName $true $global:Creds)
         }
         else
         {
             $global:observableCollection.Insert(0,(LogMessage -strMessage "Bad user name or password!" -strType "Error" -DateStamp ))
             $lblEffectiveSelUser.Content = ""
         }
     }
     else
     {
        $global:observableCollection.Insert(0,(LogMessage -strMessage "Faild to insert credentials!" -strType "Error" -DateStamp ))

     }
}
else
{
    if ( $global:strDomainPrinDNName -eq $global:strDomainDNName )
    {
        $lblSelectPrincipalDom.Content = $global:strDomainShortName+":"
        $global:strPinDomDC = $global:strDC
        $global:strPrincipalDN = (GetSecPrinDN $strPrincipal $strDomainDistinguishedName $false)
    }
    else
    {
        $global:strPinDomDC = $(GetDomainController $global:strDomainPrinDNName $false)
        $global:strPrincipalDN = (GetSecPrinDN $strPrincipal $strDomainDistinguishedName $false)
    }
}
if ($global:strPrincipalDN -eq "")
{
    $global:observableCollection.Insert(0,(LogMessage -strMessage "Could not find $strPrincipal!" -strType "Error" -DateStamp ))
    $lblEffectiveSelUser.Content = ""
}
else
{
    $global:strEffectiveRightAccount = $strPrincipal
    $global:observableCollection.Insert(0,(LogMessage -strMessage "Found security principal" -strType "Info" -DateStamp ))
    if ($global:strPrinDomDir -eq 2)
    {
        [System.Collections.ArrayList] $global:tokens = @(GetTokenGroups $global:strPrincipalDN $true $global:Creds)

        $objADPrinipal = new-object DirectoryServices.DirectoryEntry("LDAP://$global:strPinDomDC/$global:strPrincipalDN",$global:Creds.UserName,$global:Creds.GetNetworkCredential().Password)


        $objADPrinipal.psbase.RefreshCache("msDS-PrincipalName")
        $strPrinName = $($objADPrinipal.psbase.Properties.Item("msDS-PrincipalName"))
        $global:strSPNobjectClass = $($objADPrinipal.psbase.Properties.Item("objectClass"))[$($objADPrinipal.psbase.Properties.Item("objectClass")).count-1]
        if (($strPrinName -eq "") -or ($strPrinName -eq $null))
        {
        $strNETBIOSNAME = $global:strPrinDomFlat
        $strPrinName = "$strNETBIOSNAME\$($objADPrinipal.psbase.Properties.Item("samAccountName"))"
        }
        $global:strEffectiveRightSP = $strPrinName
        $global:tokens.Add($strPrinName)
        $lblEffectiveSelUser.Content = $strPrinName
    }
    else
    {
        [System.Collections.ArrayList] $global:tokens = @(GetTokenGroups $global:strPrincipalDN $false)


        $objADPrinipal = new-object DirectoryServices.DirectoryEntry("LDAP://$global:strPinDomDC/$global:strPrincipalDN")


        $objADPrinipal.psbase.RefreshCache("msDS-PrincipalName")
        $strPrinName = $($objADPrinipal.psbase.Properties.Item("msDS-PrincipalName"))
        $global:strSPNobjectClass = $($objADPrinipal.psbase.Properties.Item("objectClass"))[$($objADPrinipal.psbase.Properties.Item("objectClass")).count-1]
        if (($strPrinName -eq "") -or ($strPrinName -eq $null))
        {
        $strNETBIOSNAME = $global:strPrinDomFlat
        $strPrinName = "$strNETBIOSNAME\$($objADPrinipal.psbase.Properties.Item("samAccountName"))"
        }
        $global:strEffectiveRightSP = $strPrinName
        $global:tokens.Add($strPrinName)
        $lblEffectiveSelUser.Content = $strPrinName
    }

}

}



function LoadProgressBar
{
$global:ProgressBarWindow = [hashtable]::Synchronized(@{})
$newRunspace =[runspacefactory]::CreateRunspace()
$newRunspace.ApartmentState = "STA"
$newRunspace.ThreadOptions = "ReuseThread"
$newRunspace.Open()
$newRunspace.SessionStateProxy.SetVariable("global:ProgressBarWindow",$global:ProgressBarWindow)
$psCmd = [PowerShell]::Create().AddScript({
    [xml]$xamlProgressBar = @"
<Window x:Class="WpfApplication1.StatusBar"
         xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        x:Name="Window" Title="Scanning..." WindowStartupLocation = "CenterScreen"
        Width = "350" Height = "150" ShowInTaskbar = "False" ResizeMode="NoResize" WindowStyle="ToolWindow" Opacity="0.9" Background="#FF165081" >
    <Grid>
        <StackPanel >
            <Label x:Name="lblProgressBarInfo" Foreground="white" Content="Currently scanning 0 of 0 objects" HorizontalAlignment="Center" Margin="10,20,0,0"  FontWeight="Bold" FontSize="14"/>
            <ProgressBar  x:Name = "ProgressBar" HorizontalAlignment="Left" Height="23" Margin="10,0,0,0" VerticalAlignment="Top" Width="320"   >
                <ProgressBar.Foreground>
                    <LinearGradientBrush EndPoint="1,0.5" StartPoint="0,0.5">
                        <GradientStop Color="#FF237026"/>
                        <GradientStop Color="#FF0BF815" Offset="1"/>
                        <GradientStop Color="#FF0BF815" Offset="1"/>
                    </LinearGradientBrush>
                </ProgressBar.Foreground>
            </ProgressBar>
        </StackPanel>

    </Grid>
</Window>
"@

$xamlProgressBar.Window.RemoveAttribute("x:Class")
    $reader=(New-Object System.Xml.XmlNodeReader $xamlProgressBar)
    $global:ProgressBarWindow.Window=[Windows.Markup.XamlReader]::Load( $reader )
    $global:ProgressBarWindow.lblProgressBarInfo = $global:ProgressBarWindow.window.FindName("lblProgressBarInfo")
    $global:ProgressBarWindow.ProgressBar = $global:ProgressBarWindow.window.FindName("ProgressBar")
    $global:ProgressBarWindow.ProgressBar.Value = 0
    $global:ProgressBarWindow.Window.ShowDialog() | Out-Null
    $global:ProgressBarWindow.Error = $Error
})
$psCmd.Runspace = $newRunspace

$data = $psCmd.BeginInvoke()



}
Function Update-ProgressBar
{
Param ($txtlabel,$valProgress)

        &{#Try
           $global:ProgressBarWindow.ProgressBar.Dispatcher.invoke([action]{ $global:ProgressBarWindow.lblProgressBarInfo.Content = $txtlabel;$global:ProgressBarWindow.ProgressBar.Value = $valProgress},"Normal")

        }
        Trap [SystemException]
        {
            $global:observableCollection.Insert(0,(LogMessage -strMessage "Progressbar Failed!" -strType "Error" -DateStamp ))

        }

}




#Number of columns in CSV import
$global:intColCount = 15
$global:intDiffCol = 0
$global:myPID = $PID
$HistACLs = New-Object System.Collections.ArrayList
$CurrentFSPath = split-path -parent $MyInvocation.MyCommand.Path
$strLastCacheGuidsDom = ""
$TNRoot = ""
$global:prevNodeText = ""
$sd = ""



[void]$ADACLGui.Window.ShowDialog()
