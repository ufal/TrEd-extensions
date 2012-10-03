<?php
/*
 *
 * This script reads infromation about extensions in core and external repository
 * and displays them as formated HTML page. The script does not require any URL
 * parameters nor handles any HTTP POST requests.
 *
 * (C) 2012, Martin Krulis <krulis@ksi.mff.cuni.cz>
 *
 */


/**
 * \brief Format size in bytes to human readable format with proper units.
 * \param $size Size as int or float in bytes.
 * \return String with human readable representation of the size.
 */
function format_size_str($size)
{
	// Make sure size is a number.
	$size = (float)$size;
	
	// Find proper order for the units.
	$units = array('B', 'kB', 'MB', 'GB', 'TB');
	while ($size >= 1000 && $units) {
		$size = $size / 1024.0;
		array_shift($units);
	}
	
	// Round the result and append proper unit.
	return round($size, 1) . ' ' . $units[0];
}


/**
 * \brief Package info objects wrap data loaded from package.xml files.
 */
class PackageInfo
{
	private $name;				///< Name (formal designation) of the extension.
	private $title;				///< Human-readable name of the extension.
	private $version;			///< Version represented as string.
	private $copyright;			///< Copyright string (containing year and names).
	private $description;		///< Description text.
	private $icon;				///< Relative path to icon file.
	private $downloadSize;		///< Size of the ZIPed package.
	private $installedSize;		///< Size after installation.
	private $docUrl;			///< Relative path to index.html of the documentation (or NULL, if documentation is missing).
	
	
	/**
	 * \brief Retrieve data form package.xml file of selected package and
	 *		fills them to the package info object.
	 * \param $fileName Path to the xml file from which the data are gathered.
	 */
	public function __construct($fileName)
	{
		// Check existence and load XML package file.
		if (!is_readable($fileName))
			throw new Exception("Unable to open XML package file '$fileName'.");

		$extension = @simplexml_load_file($fileName);
		if ($extension == null)
			throw new Exception("Unable to parse XML package file '$fileName'.");
		
		// Acquire paths to package directory and the repository itself.
		$packagePath = dirname($fileName);
		$reposPath = dirname($packagePath);
		if (!$reposPath) $reposPath = '.';
		
		// Fill in data from XML.
		$this->name = $extension->pkgname;
		$this->title = $extension->title;
		$this->version = $extension->version;
		$this->copyright = $extension->copyright['year'] . ' by ' . $extension->copyright;
		$this->description = $extension->description;
		$this->icon = ($extension->icon)
			? "$packagePath/$extension->icon" : 'extension.png';
		$this->installedSize = format_size_str($extension['install_size']);

		// Find package ZIP file and get its size.
		$packageZipFile = "$reposPath/{$this->name}.zip";
		if (!is_readable($packageZipFile))
			throw new Exception("Unable to locate package file '$packageZipFile'.");
		$this->downloadSize = format_size_str(filesize($packageZipFile));

		// Get the URL to the documentation index of the package.
		$this->docUrl = "$packagePath/documentation/index.html";
		if (!is_readable($this->docUrl))
			$this->docUrl = null;
	}
	
	
	/**
	 * \brief Return string with formated HTML fragment containing the info data.
	 */
	public function getHTMLInfo()
	{
		// More info link is present only if docUrl exists.
		$moreInfo = ($this->docUrl != null)
			? '<div class="moreinfo"><a href="' . $this->docUrl . '">More info...</a></div>'
			: '';

		return '
			<div class="package">
				<div class="pkghead">
					<span class="pkgtitle">' . $this->title . '</span>
					<span class="version">' . "($this->name $this->version)" . '</span>
				</div>
				<div class="desc">
					<img src="' . $this->icon . '" class="pkgicon" alt="package icon" />
					' . $this->description . $moreInfo . '
				</div>
				<div class="size">' . "Size: $this->downloadSize package / $this->installedSize installed" . '</div>
				<div class="copyright">' . "Copyright (c) $this->copyright" . '</div>
				<div style="clear:both"></div>
			</div>';
	}
}



/**
 * \brief Retrieve a list of packages in the repository.
 * \param $listFile Path to the list file.
 * \return Array of package names.
 */
function get_packages($listFile)
{
	// Read entire file as an array (on line is one item).
	if (!is_readable($listFile))
		throw new Exception("Unable to find extensions list file '$listFile'.");
	$names = @file($listFile);
	
	// Make sure each line is properly trimed.
	foreach ($names as &$name)
		$name = trim($name);
		
	return $names;
}



/**
 * \brief Show (print out as HTML) all packages in given repository.
 * \param $repository Path to selected repository.
 */
function show_extensions($repository)
{
	try {
		$packages = get_packages("$repository/extensions.lst");
		if (!$packages)
			echo '<p>No packages were found.</p>';
		
		foreach ($packages as $package) {
			if (!$package) continue;
			$info = new PackageInfo("$repository/$package/package.xml");
			echo $info->getHTMLInfo();
		}
	}
	catch (Exception $e) {
		echo "<p>\n";
		echo 'Error: ' . $e->getMessage() . "\n";
		echo "</p>\n";
	}
}


?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>TrEd Extensions</title>
<style type="text/css">
* {
  font-family: sans;
}

h1, h2 {
	margin: 30pt 10pt 20pt;
}

p {
	margin: 10pt 30pt;
}

.package {
   background-color: #ffffff;
   border: solid 1px #aaf;
 /*   padding: 0 12pt 6pt 12pt; */
   margin: 10pt 10pt 10pt 10pt;
}

.pkghead {
    background-color: #eeeeff;
    padding: 3pt 3pt 3pt 3pt;
}

.pkgtitle {
    font-weight: bold;
    padding: 3pt 3pt 3pt 3pt;
}

.desc {
    padding: 3pt 3pt 3pt 3pt;
}
.size, .copyright, .moreinfo {
  float: right;
  clear: right;
  padding: 3pt 6pt 0pt 3pt;
  text-align: right;
}

.size {
  font-size: 7pt;
}
.copyright {
    font-size: 7pt;
    font-style: italic;
    color: #666;
	margin-bottom: 10px;
}
.moreinfo a {
    font-size: 8pt;
}
.version {
    text-align: right;
}
.pkgicon {
  float: left;
  padding: 6pt 6pt 6pt 6pt
}
</style>
</head>
<body>

<h1>TrEd Extensions</h1>
<p>
	Please note that this list is only a preview. You can download and install extensions directly from
	<a href="http://ufal.mff.cuni.cz/tred">TrEd application</a>.
</p>

<h2>Core Extensions</h2>
<?php
	show_extensions('core');
?>

<h2>External Extensions</h2>
<?php
	show_extensions('external');
?>

</body>
</html>
