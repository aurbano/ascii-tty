#! /usr/bin/env perl 

use GD::Image;
use Term::ANSIColor;
use Pod::Usage;
use Getopt::Long;
use Term::ReadKey;

# Terminal data
($wchar, $hchar, $wpixels, $hpixels) = GetTerminalSize();

# Parse parameters and options
my $imgsrc;
my $resolution = $wchar - 1;
my $vstretch = 0.5;
my $threshold = 30;
my $color = 0;
my $average = 0;
my $help = 0;
my $man = 0;

GetOptions (
  "color" => \$color,
  "resolution=f" => \$resolution,
  "vstretch=f" => \$vstretch,
  "threshold=f" => \$threshold,
  "average" => \$average,
  "help|?" => \$help,
  "man" => \$man
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;

my $im;
$imgsrc = shift;

# Help message if no image was specified
if(!$imgsrc){
  pod2usage(1);
}

GD::Image->trueColor(1);
$im = GD::Image->new($imgsrc)
  or die "ascii-ttl.pl: can't find '",$imgsrc,"'\n";

# Get image size
my @size = $im->getBounds();

# Scanning resolution
my $resx = @size[0]/$resolution;
my $resy = $resx/$vstretch;

# Filling chars
my @chars = (" ", ".", ",", "-", "+", "1", "b", "#", "X", "W", "W");

# Build array of average values
for(my $y=0; $y <= @size[1]; $y = $y+$resy){
  for(my $x=0; $x <= @size[0]; $x = $x+$resx){
    my @avgRGB = (0,0,0);
    if($average > 0){
      # sample area averaging enabled
      my $counter = 0;
      for my $sampley (0 .. $resy){
        for my $samplex (0 .. $resx){
          my $pixel = $im->getPixel($x + $samplex, $y + $sampley);
          if($pixel >= 1<<24){
            $counter++;
            next;
          }
          ($r,$g,$b) = $im->rgb($pixel);
          $avgRGB[0] += $r;
          $avgRGB[1] += $g;
          $avgRGB[2] += $b;
          $counter++;
        }
      }
      $avgRGB[0] /= $counter;
      $avgRGB[1] /= $counter;
      $avgRGB[2] /= $counter;
    }else{
       #Simple way of getting the average, without sampling
      my $index = $im->getPixel(int($x),int($y));
      if($index >= 1<<24){    
        # Transparent pixel
        print " ";
        next;
      }
      ($r,$g,$b) = $im->rgb($im->getPixel(int($x),int($y)));
      $avgRGB[0] = $r;
      $avgRGB[1] = $g;
      $avgRGB[2] = $b;
    }
    my $avg = ($avgRGB[0]+$avgRGB[1]+$avgRGB[2])/3;
    # Get the average value and normalize it to 0-1
    my $norm = 20*$avg/255;
    # Decide which color (if any) to print
    print color 'on_black';
      if($color > 0){
      my $closest = "white";
      my $closestDiff = 255*3 + $threshold;
      my %colorList = (
         #color => (r,g,b)
        "black" => [0,0,0],
        "white" => [255,255,255],
        "red" => [255,0,0],
        "green" => [0,255,0],
        "yellow" => [255,255,0],
        "blue" => [0,0,255],
        "magenta" => [255,0,255],
        "cyan" => [0,255,255],
      );
      foreach my $color (keys %colorList){
        @rgb = @{$colorList{$color}};
        my $diff = abs($avgRGB[0]-$rgb[0]) + abs($avgRGB[1]-$rgb[1]) + abs($avgRGB[2]-$rgb[2]);
        if($diff - $threshold < $closestDiff){
          $closestDiff = $diff;
          $closest = $color;
        }
      }
      print color $closest;
    }
    if($norm > 10){
      print color 'bold';
      print @chars[int($norm/2)];
      print color 'reset';
    }else{
      print @chars[int($norm/2)];
    }
    print color 'reset';
  }
  print "\n";
}

# Sampling is very slow at the moment, so disabled
# The following code does area sampling, generating
# more detailed images
    


__END__

=head1 NAME

ascii-tty - Print images on the terminal using ascii art

=head1 SYNOPSIS

ascii-tty [-c] [-r resolution] [-t threshold] [-s vertical stretching] [-a average] image

=head1 DESCRIPTION

B<ascii-tty> takes any image filename as an input and will output text
via stdout that looks similar to the image.
It can also output colored text (8 colors by default)

=head1 OPTIONS

=over 8

=item B<-c>

Enable colored output

=item B<-a>

Enable averaging for the image sampling algorithm. Averaging should produce closer representations of the input image, but will slow down the process.

=item B<-t>

Color sampling threshold, a higher threshold will generate less transitions between colors in the images, good for images with gradients.

=item B<-r>

The resolution is the number of columns used when printing the image.
It will default to the current size of the terminal.

=item B<-s>

Vertical stretching factor for the image, or aspect ratio.
It defaults to 0.5, numbers over 0.5 will stretch the image vertically, under 0.5 they will compress it.

=back

=head1 HISTORY

B<ascii-tty> was released on 15 Sep 2015

=cut