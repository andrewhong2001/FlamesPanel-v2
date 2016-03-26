<?php
require('check.php');
include('../inc/header.php');
include('../inc/navbar.php');

function clean($string) {

   $string = str_replace(' ', '-', $string); // Replaces all spaces with hyphens.
   $string = preg_replace('/[^A-Z.a-z0-9\-]/', '', $string); // Removes special chars.

   return preg_replace('/-+/', '-', $string); // Replaces multiple hyphens with single one.
}

$username = $_SESSION['username'];

if ($_POST['type_of_domain'] == "subdomain"){
$_POST['domain_name'] = preg_replace('/[.,]/', '', $_POST["domain_name"]);
$_POST['domain_name'] = $_POST['domain_name'].".userspace.flameshost.com";}

$currentvhost = shell_exec('cat /etc/httpd/conf.d/vhosts.conf');
$pending = shell_exec('cat /tmp/vhosts/newvhost.conf');
//$domain1 = htmlspecialchars($_POST['domain_name']);
$domain1 = $_POST['domain_name'];
$domain2 = clean($domain1);
$domain = escapeshellcmd($domain2);
if ($_POST['type_of_domain'] == "subdomain"){
$valid_domain = "valid";
} else {
$valid_domain = shell_exec('curl -q -s http://domaincheck.userspace.flameshost.com/?domain='.$domain);
}
$exists = shell_exec('/bin/vhost_check '.$domain);
$tmpCheck = shell_exec('/bin/tmp_check '.$domain);

?>

<body>

<script src="style.js"></script>
<link href="style.css" rel="stylesheet" type="text/css">

<br> </br>
<div class="jumbotron">
<div class="container">
<h1>Add a website</h1>
<p>This is where you can add hosted domains to your account</p>
<p>Do note, custom domains <b>MUST EXIST</b> in the WHOIS database and be registered.</p>
<?php
$bwcalc = shell_exec('/bin/is_premium '.$username);
if ($bwcalc == 1){
$bw = "25GB"; 
} else {
$bw = "5GB";
}
?>
<p>Bandwidth allocated per website: <b><?php echo $bw; ?></b> </p>
<?php
if (!isset($_POST['domain_name'])){
?>
<form action="." method="POST" id="createAcct" onsubmit="loading();">
<div class="input-group">
<input id="domainBox" type="text" class="form-control" name="domain_name" placeholder="New domain name..." />
<span class="input-group-btn">
<button id="activateBtn" onclick="loading()" type="submit" form="createAcct" value="Add website" class="btn btn-success">Submit</button>
</span>
</div>
</form>
<br>
<form id="addSubdomain" action="." method="POST" onsubmit="loading2();">
  <input type="hidden" value="subdomain" name="type_of_domain" />
<div class="input-group">
  <input id="domainBox2" type="text" class="form-control" name="domain_name" placeholder="yoursubdomain.userspace.flameshost.com" aria-describedby="basic-addon2">
  <span class="input-group-addon" id="basic-addon2">.userspace.flameshost.com</span>
  <span class="input-group-btn">
<button id="activateBtn2" onclick="loading2()" type="submit" form="addSubdomain" value="Add subdomain" class="btn btn-primary">Add subdomain</a>
  </span>
</div>
</form>

<?php
}

if ($exists == 0){
echo '<div class="alert alert-danger"><b>Error:</b> This domain name already exists in our system.</div>';
echo '<a href="." class="btn btn-info btn-lg">Back</a>';
echo '</div></div></body><div class="container">';
include('../../inc/footer.php'); 
echo '</div>';
die();
}

if ($tmpCheck == 0){
echo '<div class="alert alert-danger"><b>Error:</b> This domain name is currently pending for setup.</div>';
echo '<a href="." class="btn btn-info btn-lg">Back</a>';
echo '</div></div></body><div class="container">';
include('../../inc/footer.php');
echo '</div>';
die();
}

if (isset($_POST['domain_name'])){
if ($valid_domain == "invalid"){
echo '<div class="alert alert-danger"><b>Error:</b> This domain name has not been registered and/or does not exist in the WHOIS database.</div>';
echo '<a href="." class="btn btn-success">Back</a>';
} else {
$data = shell_exec('/bin/apache_newsite '.$domain.' '.$username);
$nameserver = shell_exec('/bin/apache_ns '.$domain);
echo '<p>Response from server:</p>';
echo '<pre>'.$data.'</pre>';
echo '<a href="." class="btn btn-success">Back</a>';
}
}
?>
<br>
<h3>Your Active Websites</h3>
<?php
$websites1 = shell_exec("/bin/apache_listwebsites ".$username);
$pendingWebsites1 = shell_exec("/bin/apache_listpending ".$username);
$websites2 = str_replace("#", "", $websites1);
$websites = str_replace("/ ".$username, "", $websites2);
$pendingWebsites2 = str_replace("#", "", $pendingWebsites1);
$pendingWebsites = str_replace("/ ".$username, "", $pendingWebsites2);

?>

<div class="table-responsive">
  <table class="table table-hover table-bordered">
    <thead>
      <tr>
        <th>Website</th>
        <th>Bandwidth</th>
        <th>Dedicated IPv6 Address</th>
        <th>Logs</th>
        <th>Purge Website</th>
      </tr>
    </thead>
    <tbody>

<?php
//$separator = "\r\n";
//$line = strtok($websites, $separator);
//$line = strtok($websites, $separator);
//while ($line !== false) {
//    # do something with $line
//    $line = strtok($separator);
//    $trimmed = trim($line);
//    if (empty($trimmed)){
//    } else {
//    echo $trimmed." - <a href='http://".$trimmed."/myBW' target='_blank'>Bandwidth Viewer</a><br>";
//    }
//}
if (preg_match('/none/',$websites)){
echo '<tr><td>None</td><td></td><td></td><td></td><td></td></tr>';
} else {


$lines = split("\n", $websites);
foreach ($lines as $line) {
    $trimmed = trim($line);
    if (empty($trimmed)){
    } else {
    $ipv6_of_domain = shell_exec('/bin/apache_getv6 '.$trimmed);
    $processedv6 = str_replace("#", "", $ipv6_of_domain);
    $finalv62 = str_replace("- ".$trimmed, "", $processedv6);
    $finalv6 = trim($finalv62);
    echo '<tr><td>'.$trimmed."</td><td><a href='http://".$trimmed."/myBW' target='_blank' class='btn btn-success'>Bandwidth Viewer</a></td><td>".$finalv6."</td><td><a target='_blank' href='/dashboard/manage-websites/view_logs.php?domain=".$trimmed."' class='btn btn-info'>View Logs</a></td><td><a href='delete_website.php?domain=".$trimmed."' target='_blank' class='btn btn-danger'>Delete Website</a></td></tr>";
    }
}  
}
?>
</tbody>
</table>
</div>
<br>
<h3>Pending websites</h3>
<pre>
<?php
echo $pendingWebsites;
?>
</pre>
<br>
<a href="." class="btn btn-info">Refresh</a>
<br> </br>
<?php include('../../inc/footer.php'); ?>
</div>
</div>
</body>

