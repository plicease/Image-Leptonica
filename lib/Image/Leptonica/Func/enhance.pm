package Image::Leptonica::Func::enhance;

=head1 C<enhance.c>

  enhance.c

      Gamma TRC (tone reproduction curve) mapping
           PIX     *pixGammaTRC()
           PIX     *pixGammaTRCMasked()
           PIX     *pixGammaTRCWithAlpha()
           NUMA    *numaGammaTRC()

      Contrast enhancement
           PIX     *pixContrastTRC()
           PIX     *pixContrastTRCMasked()
           NUMA    *numaContrastTRC()

      Histogram equalization
           PIX     *pixEqualizeTRC()
           NUMA    *numaEqualizeTRC()

      Generic TRC mapper
           PIX     *pixTRCMap()

      Unsharp-masking
           PIX     *pixUnsharpMasking()
           PIX     *pixUnsharpMaskingGray()
           PIX     *pixUnsharpMaskingFast()
           PIX     *pixUnsharpMaskingGrayFast()
           PIX     *pixUnsharpMaskingGray1D()
           PIX     *pixUnsharpMaskingGray2D()

      Hue and saturation modification
           PIX     *pixModifyHue()
           PIX     *pixModifySaturation()
           l_int32  pixMeasureSaturation()
           PIX     *pixModifyBrightness()

      Color shifting
           PIX     *pixColorShiftRGB()

      General multiplicative constant color transform
           PIX     *pixMultConstantColor()
           PIX     *pixMultMatrixColor()

      Edge by bandpass
           PIX     *pixHalfEdgeByBandpass()

      Gamma correction, contrast enhancement and histogram equalization
      apply a simple mapping function to each pixel (or, for color
      images, to each sample (i.e., r,g,b) of the pixel).

       - Gamma correction either lightens the image or darkens
         it, depending on whether the gamma factor is greater
         or less than 1.0, respectively.

       - Contrast enhancement darkens the pixels that are already
         darker than the middle of the dynamic range (128)
         and lightens pixels that are lighter than 128.

       - Histogram equalization remaps to have the same number
         of image pixels at each of 256 intensity values.  This is
         a quick and dirty method of adjusting contrast and brightness
         to bring out details in both light and dark regions.

      Unsharp masking is a more complicated enhancement.
      A "high frequency" image, generated by subtracting
      the smoothed ("low frequency") part of the image from
      itself, has all the energy at the edges.  This "edge image"
      has 0 average value.  A fraction of the edge image is
      then added to the original, enhancing the differences
      between pixel values at edges.  Because we represent
      images as l_uint8 arrays, we preserve dynamic range and
      handle negative values by doing all the arithmetic on
      shifted l_uint16 arrays; the l_uint8 values are recovered
      at the end.

      Hue and saturation modification work in HSV space.  Because
      this is too large for efficient table lookup, each pixel value
      is transformed to HSV, modified, and transformed back.
      It's not the fastest way to do this, but the method is
      easily understood.

      Unsharp masking is never in-place, and returns a clone if no
      operation is to be performed.

=head1 FUNCTIONS

=head2 numaContrastTRC

NUMA * numaContrastTRC ( l_float32 factor )

  numaContrastTRC()

      Input:  factor (generally between 0.0 (no enhancement)
              and 1.0, but can be larger than 1.0)
      Return: na, or null on error

  Notes:
      (1) The mapping is monotonic increasing, where 0 is mapped
          to 0 and 255 is mapped to 255.
      (2) As 'factor' is increased from 0.0 (where the mapping is linear),
          the map gets closer to its limit as a step function that
          jumps from 0 to 255 at the center (input value = 127).

=head2 numaEqualizeTRC

NUMA * numaEqualizeTRC ( PIX *pix, l_float32 fract, l_int32 factor )

  numaEqualizeTRC()

      Input:  pix (8 bpp, no colormap)
              fract (fraction of equalization movement of pixel values)
              factor (subsampling factor; integer >= 1)
      Return: nad, or null on error

  Notes:
      (1) If fract == 0.0, no equalization will be performed.
          If fract == 1.0, equalization is complete.
      (2) Set the subsampling factor > 1 to reduce the amount of computation.
      (3) The map is returned as a numa with 256 values, specifying
          the equalized value (array value) for every input value
          (the array index).

=head2 numaGammaTRC

NUMA * numaGammaTRC ( l_float32 gamma, l_int32 minval, l_int32 maxval )

  numaGammaTRC()

      Input:  gamma   (gamma factor; must be > 0.0)
              minval  (input value that gives 0 for output)
              maxval  (input value that gives 255 for output)
      Return: na, or null on error

  Notes:
      (1) The map is returned as a numa; values are clipped to [0, 255].
      (2) To force all intensities into a range within fraction delta
          of white, use: minval = -256 * (1 - delta) / delta
                         maxval = 255
      (3) To force all intensities into a range within fraction delta
          of black, use: minval = 0
                         maxval = 256 * (1 - delta) / delta

=head2 pixColorShiftRGB

PIX * pixColorShiftRGB ( PIX *pixs, l_float32 rfract, l_float32 gfract, l_float32 bfract )

  pixColorShiftRGB()

      Input:  pixs (32 bpp rgb)
              rfract (fractional shift in red component)
              gfract (fractional shift in green component)
              bfract (fractional shift in blue component)
      Return: pixd, or null on error

  Notes:
      (1) This allows independent fractional shifts of the r,g and b
          components.  A positive shift pushes to saturation (255);
          a negative shift pushes toward 0 (black).
      (2) The effect can be imagined using a color wheel that consists
          (for our purposes) of these 6 colors, separated by 60 degrees:
             red, magenta, blue, cyan, green, yellow
      (3) So, for example, a negative shift of the blue component
          (bfract < 0) could be accompanied by positive shifts
          of red and green to make an image more yellow.
      (4) Examples of limiting cases:
            rfract = 1 ==> r = 255
            rfract = -1 ==> r = 0

=head2 pixContrastTRC

PIX * pixContrastTRC ( PIX *pixd, PIX *pixs, l_float32 factor )

  pixContrastTRC()

      Input:  pixd (<optional> null or equal to pixs)
              pixs (8 or 32 bpp; or 2, 4 or 8 bpp with colormap)
              factor  (0.0 is no enhancement)
      Return: pixd always

  Notes:
      (1) pixd must either be null or equal to pixs.
          For in-place operation, set pixd == pixs:
             pixContrastTRC(pixs, pixs, ...);
          To get a new image, set pixd == null:
             pixd = pixContrastTRC(NULL, pixs, ...);
      (2) If pixs is colormapped, the colormap is transformed,
          either in-place or in a copy of pixs.
      (3) Contrast is enhanced by mapping each color component
          using an atan function with maximum slope at 127.
          Pixels below 127 are lowered in intensity and pixels
          above 127 are increased.
      (4) The useful range for the contrast factor is scaled to
          be in (0.0 to 1.0), but larger values can also be used.
      (5) If factor == 0.0, no enhancement is performed; return a copy
          unless in-place, in which case this is a no-op.
      (6) For color images that are not colormapped, the mapping
          is applied to each component.

=head2 pixContrastTRCMasked

PIX * pixContrastTRCMasked ( PIX *pixd, PIX *pixs, PIX *pixm, l_float32 factor )

  pixContrastTRCMasked()

      Input:  pixd (<optional> null or equal to pixs)
              pixs (8 or 32 bpp; or 2, 4 or 8 bpp with colormap)
              pixm (<optional> null or 1 bpp)
              factor  (0.0 is no enhancement)
      Return: pixd always

  Notes:
      (1) Same as pixContrastTRC() except mapping is optionally over
          a subset of pixels described by pixm.
      (2) Masking does not work for colormapped images.
      (3) See pixContrastTRC() for details on how to use the parameters.

=head2 pixEqualizeTRC

PIX * pixEqualizeTRC ( PIX *pixd, PIX *pixs, l_float32 fract, l_int32 factor )

  pixEqualizeTRC()

      Input:  pixd (<optional> null or equal to pixs)
              pixs (8 bpp gray, 32 bpp rgb, or colormapped)
              fract (fraction of equalization movement of pixel values)
              factor (subsampling factor; integer >= 1)
      Return: pixd, or null on error

  Notes:
      (1) pixd must either be null or equal to pixs.
          For in-place operation, set pixd == pixs:
             pixEqualizeTRC(pixs, pixs, ...);
          To get a new image, set pixd == null:
             pixd = pixEqualizeTRC(NULL, pixs, ...);
      (2) In histogram equalization, a tone reproduction curve
          mapping is used to make the number of pixels at each
          intensity equal.
      (3) If fract == 0.0, no equalization is performed; return a copy
          unless in-place, in which case this is a no-op.
          If fract == 1.0, equalization is complete.
      (4) Set the subsampling factor > 1 to reduce the amount of computation.
      (5) If pixs is colormapped, the colormap is removed and
          converted to rgb or grayscale.
      (6) If pixs has color, equalization is done in each channel
          separately.
      (7) Note that even if there is a colormap, we can get an
          in-place operation because the intermediate image pixt
          is copied back to pixs (which for in-place is the same
          as pixd).

=head2 pixGammaTRC

PIX * pixGammaTRC ( PIX *pixd, PIX *pixs, l_float32 gamma, l_int32 minval, l_int32 maxval )

  pixGammaTRC()

      Input:  pixd (<optional> null or equal to pixs)
              pixs (8 or 32 bpp; or 2, 4 or 8 bpp with colormap)
              gamma (gamma correction; must be > 0.0)
              minval  (input value that gives 0 for output; can be < 0)
              maxval  (input value that gives 255 for output; can be > 255)
      Return: pixd always

  Notes:
      (1) pixd must either be null or equal to pixs.
          For in-place operation, set pixd == pixs:
             pixGammaTRC(pixs, pixs, ...);
          To get a new image, set pixd == null:
             pixd = pixGammaTRC(NULL, pixs, ...);
      (2) If pixs is colormapped, the colormap is transformed,
          either in-place or in a copy of pixs.
      (3) We use a gamma mapping between minval and maxval.
      (4) If gamma < 1.0, the image will appear darker;
          if gamma > 1.0, the image will appear lighter;
      (5) If gamma = 1.0 and minval = 0 and maxval = 255, no
          enhancement is performed; return a copy unless in-place,
          in which case this is a no-op.
      (6) For color images that are not colormapped, the mapping
          is applied to each component.
      (7) minval and maxval are not restricted to the interval [0, 255].
          If minval < 0, an input value of 0 is mapped to a
          nonzero output.  This will turn black to gray.
          If maxval > 255, an input value of 255 is mapped to
          an output value less than 255.  This will turn
          white (e.g., in the background) to gray.
      (8) Increasing minval darkens the image.
      (9) Decreasing maxval bleaches the image.
      (10) Simultaneously increasing minval and decreasing maxval
           will darken the image and make the colors more intense;
           e.g., minval = 50, maxval = 200.
      (11) See numaGammaTRC() for further examples of use.

=head2 pixGammaTRCMasked

PIX * pixGammaTRCMasked ( PIX *pixd, PIX *pixs, PIX *pixm, l_float32 gamma, l_int32 minval, l_int32 maxval )

  pixGammaTRCMasked()

      Input:  pixd (<optional> null or equal to pixs)
              pixs (8 or 32 bpp; not colormapped)
              pixm (<optional> null or 1 bpp)
              gamma (gamma correction; must be > 0.0)
              minval  (input value that gives 0 for output; can be < 0)
              maxval  (input value that gives 255 for output; can be > 255)
      Return: pixd always

  Notes:
      (1) Same as pixGammaTRC() except mapping is optionally over
          a subset of pixels described by pixm.
      (2) Masking does not work for colormapped images.
      (3) See pixGammaTRC() for details on how to use the parameters.

=head2 pixGammaTRCWithAlpha

PIX * pixGammaTRCWithAlpha ( PIX *pixd, PIX *pixs, l_float32 gamma, l_int32 minval, l_int32 maxval )

  pixGammaTRCWithAlpha()

      Input:  pixd (<optional> null or equal to pixs)
              pixs (32 bpp)
              gamma (gamma correction; must be > 0.0)
              minval  (input value that gives 0 for output; can be < 0)
              maxval  (input value that gives 255 for output; can be > 255)
      Return: pixd always

  Notes:
      (1) See usage notes in pixGammaTRC().
      (2) This version saves the alpha channel.  It is only valid
          for 32 bpp (no colormap), and is a bit slower.

=head2 pixHalfEdgeByBandpass

PIX * pixHalfEdgeByBandpass ( PIX *pixs, l_int32 sm1h, l_int32 sm1v, l_int32 sm2h, l_int32 sm2v )

  pixHalfEdgeByBandpass()

      Input:  pixs (8 bpp gray or 32 bpp rgb)
              sm1h, sm1v ("half-widths" of smoothing filter sm1)
              sm2h, sm2v ("half-widths" of smoothing filter sm2)
                      (require sm2 != sm1)
      Return: pixd, or null on error

  Notes:
      (1) We use symmetric smoothing filters of odd dimension,
          typically use 3, 5, 7, etc.  The smoothing parameters
          for these are 1, 2, 3, etc.  The filter size is related
          to the smoothing parameter by
               size = 2 * smoothing + 1
      (2) Because we take the difference of two lowpass filters,
          this is actually a bandpass filter.
      (3) We allow both filters to be anisotropic.
      (4) Consider either the h or v component of the 2 filters.
          Depending on whether sm1 > sm2 or sm2 > sm1, we get
          different halves of the smoothed gradients (or "edges").
          This difference of smoothed signals looks more like
          a second derivative of a transition, which we rectify
          by not allowing the signal to go below zero.  If sm1 < sm2,
          the sm2 transition is broader, so the difference between
          sm1 and sm2 signals is positive on the upper half of
          the transition.  Likewise, if sm1 > sm2, the sm1 - sm2
          signal difference is positive on the lower half of
          the transition.

=head2 pixMeasureSaturation

l_int32 pixMeasureSaturation ( PIX *pixs, l_int32 factor, l_float32 *psat )

  pixMeasureSaturation()

      Input:  pixs (32 bpp rgb)
              factor (subsampling factor; integer >= 1)
              &sat (<return> average saturation)
      Return: pixd, or null on error

=head2 pixModifyBrightness

PIX * pixModifyBrightness ( PIX *pixd, PIX *pixs, l_float32 fract )

  pixModifyBrightness()

      Input:  pixd (<optional> can be null, existing or equal to pixs)
              pixs (32 bpp rgb)
              fract (between -1.0 and 1.0)
      Return: pixd, or null on error

  Notes:
      (1) If fract > 0.0, it gives the fraction that the v-parameter,
          which is max(r,g,b), is moved from its initial value toward 255.
          If fract < 0.0, it gives the fraction that the v-parameter
          is moved from its initial value toward 0.
          The limiting values for fract = -1.0 (1.0) thus set the
          v-parameter to 0 (255).
      (2) If fract = 0, no modification is requested; return a copy
          unless in-place, in which case this is a no-op.
      (3) See discussion of color-modification methods, in coloring.c.

=head2 pixModifyHue

PIX * pixModifyHue ( PIX *pixd, PIX *pixs, l_float32 fract )

  pixModifyHue()

      Input:  pixd (<optional> can be null or equal to pixs)
              pixs (32 bpp rgb)
              fract (between -1.0 and 1.0)
      Return: pixd, or null on error

  Notes:
      (1) pixd must either be null or equal to pixs.
          For in-place operation, set pixd == pixs:
             pixEqualizeTRC(pixs, pixs, ...);
          To get a new image, set pixd == null:
             pixd = pixEqualizeTRC(NULL, pixs, ...);
      (1) Use fract > 0.0 to increase hue value; < 0.0 to decrease it.
          1.0 (or -1.0) represents a 360 degree rotation; i.e., no change.
      (2) If no modification is requested (fract = -1.0 or 0 or 1.0),
          return a copy unless in-place, in which case this is a no-op.
      (3) See discussion of color-modification methods, in coloring.c.

=head2 pixModifySaturation

PIX * pixModifySaturation ( PIX *pixd, PIX *pixs, l_float32 fract )

  pixModifySaturation()

      Input:  pixd (<optional> can be null, existing or equal to pixs)
              pixs (32 bpp rgb)
              fract (between -1.0 and 1.0)
      Return: pixd, or null on error

  Notes:
      (1) If fract > 0.0, it gives the fraction that the pixel
          saturation is moved from its initial value toward 255.
          If fract < 0.0, it gives the fraction that the pixel
          saturation is moved from its initial value toward 0.
          The limiting values for fract = -1.0 (1.0) thus set the
          saturation to 0 (255).
      (2) If fract = 0, no modification is requested; return a copy
          unless in-place, in which case this is a no-op.
      (3) See discussion of color-modification methods, in coloring.c.

=head2 pixMultConstantColor

PIX * pixMultConstantColor ( PIX *pixs, l_float32 rfact, l_float32 gfact, l_float32 bfact )

  pixMultConstantColor()

      Input:  pixs (colormapped or rgb)
              rfact, gfact, bfact (multiplicative factors on each component)
      Return: pixd (colormapped or rgb, with colors scaled), or null on error

  Notes:
      (1) rfact, gfact and bfact can only have non-negative values.
          They can be greater than 1.0.  All transformed component
          values are clipped to the interval [0, 255].
      (2) For multiplication with a general 3x3 matrix of constants,
          use pixMultMatrixColor().

=head2 pixMultMatrixColor

PIX * pixMultMatrixColor ( PIX *pixs, L_KERNEL *kel )

  pixMultMatrixColor()

      Input:  pixs (colormapped or rgb)
              kernel (3x3 matrix of floats)
      Return: pixd (colormapped or rgb), or null on error

  Notes:
      (1) The kernel is a data structure used mostly for floating point
          convolution.  Here it is a 3x3 matrix of floats that are used
          to transform the pixel values by matrix multiplication:
            nrval = a[0,0] * rval + a[0,1] * gval + a[0,2] * bval
            ngval = a[1,0] * rval + a[1,1] * gval + a[1,2] * bval
            nbval = a[2,0] * rval + a[2,1] * gval + a[2,2] * bval
      (2) The matrix can be generated in several ways.
          See kernel.c for details.  Here are two of them:
            (a) kel = kernelCreate(3, 3);
                kernelSetElement(kel, 0, 0, val00);
                kernelSetElement(kel, 0, 1, val01);
                ...
            (b) from a static string; e.g.,:
                const char *kdata = " 0.6  0.3 -0.2 "
                                    " 0.1  1.2  0.4 "
                                    " -0.4 0.2  0.9 ";
                kel = kernelCreateFromString(3, 3, 0, 0, kdata);
      (3) For the special case where the matrix is diagonal, it is easier
          to use pixMultConstantColor().
      (4) Matrix entries can have positive and negative values, and can
          be larger than 1.0.  All transformed component values
          are clipped to [0, 255].

=head2 pixTRCMap

l_int32 pixTRCMap ( PIX *pixs, PIX *pixm, NUMA *na )

  pixTRCMap()

      Input:  pixs (8 grayscale or 32 bpp rgb; not colormapped)
              pixm (<optional> 1 bpp mask)
              na (mapping array)
      Return: pixd, or null on error

  Notes:
      (1) This operation is in-place on pixs.
      (2) For 32 bpp, this applies the same map to each of the r,g,b
          components.
      (3) The mapping array is of size 256, and it maps the input
          index into values in the range [0, 255].
      (4) If defined, the optional 1 bpp mask pixm has its origin
          aligned with pixs, and the map function is applied only
          to pixels in pixs under the fg of pixm.
      (5) For 32 bpp, this does not save the alpha channel.

=head2 pixUnsharpMasking

PIX * pixUnsharpMasking ( PIX *pixs, l_int32 halfwidth, l_float32 fract )

  pixUnsharpMasking()

      Input:  pixs (all depths except 1 bpp; with or without colormaps)
              halfwidth  ("half-width" of smoothing filter)
              fract  (fraction of edge added back into image)
      Return: pixd, or null on error

  Notes:
      (1) We use symmetric smoothing filters of odd dimension,
          typically use sizes of 3, 5, 7, etc.  The @halfwidth parameter
          for these is (size - 1)/2; i.e., 1, 2, 3, etc.
      (2) The fract parameter is typically taken in the
          range:  0.2 < fract < 0.7
      (3) Returns a clone if no sharpening is requested.

=head2 pixUnsharpMaskingFast

PIX * pixUnsharpMaskingFast ( PIX *pixs, l_int32 halfwidth, l_float32 fract, l_int32 direction )

  pixUnsharpMaskingFast()

      Input:  pixs (all depths except 1 bpp; with or without colormaps)
              halfwidth  ("half-width" of smoothing filter; 1 and 2 only)
              fract  (fraction of high frequency added to image)
              direction (L_HORIZ, L_VERT, L_BOTH_DIRECTIONS)
      Return: pixd, or null on error

  Notes:
      (1) The fast version uses separable 1-D filters directly on
          the input image.  The halfwidth is either 1 (full width = 3)
          or 2 (full width = 5).
      (2) The fract parameter is typically taken in the
            range:  0.2 < fract < 0.7
      (3) To skip horizontal sharpening, use @fracth = 0.0; ditto for @fractv
      (4) For one dimensional filtering (as an example):
          For @halfwidth = 1, the low-pass filter is
              L:    1/3    1/3   1/3
          and the high-pass filter is
              H = I - L:   -1/3   2/3   -1/3
          For @halfwidth = 2, the low-pass filter is
              L:    1/5    1/5   1/5    1/5    1/5
          and the high-pass filter is
              H = I - L:   -1/5  -1/5   4/5  -1/5   -1/5
          The new sharpened pixel value is found by adding some fraction
          of the high-pass filter value (which sums to 0) to the
          initial pixel value:
              N = I + fract * H
      (5) For 2D, the sharpening filter is not separable, because the
          vertical filter depends on the horizontal location relative
          to the filter origin, and v.v.   So we either do the full
          2D filter (for @halfwidth == 1) or do the low-pass
          convolution separably and then compose with the original pix.
      (6) Returns a clone if no sharpening is requested.

=head2 pixUnsharpMaskingGray

PIX * pixUnsharpMaskingGray ( PIX *pixs, l_int32 halfwidth, l_float32 fract )

  pixUnsharpMaskingGray()

      Input:  pixs (8 bpp; no colormap)
              halfwidth  ("half-width" of smoothing filter)
              fract  (fraction of edge added back into image)
      Return: pixd, or null on error

  Notes:
      (1) We use symmetric smoothing filters of odd dimension,
          typically use sizes of 3, 5, 7, etc.  The @halfwidth parameter
          for these is (size - 1)/2; i.e., 1, 2, 3, etc.
      (2) The fract parameter is typically taken in the range:
          0.2 < fract < 0.7
      (3) Returns a clone if no sharpening is requested.

=head2 pixUnsharpMaskingGray1D

PIX * pixUnsharpMaskingGray1D ( PIX *pixs, l_int32 halfwidth, l_float32 fract, l_int32 direction )

  pixUnsharpMaskingGray1D()

      Input:  pixs (8 bpp; no colormap)
              halfwidth  ("half-width" of smoothing filter: 1 or 2)
              fract  (fraction of high frequency added to image)
              direction (of filtering; use L_HORIZ or L_VERT)
      Return: pixd, or null on error

  Notes:
      (1) For usage and explanation of the algorithm, see notes
          in pixUnsharpMaskingFast().
      (2) Returns a clone if no sharpening is requested.

=head2 pixUnsharpMaskingGray2D

PIX * pixUnsharpMaskingGray2D ( PIX *pixs, l_int32 halfwidth, l_float32 fract )

  pixUnsharpMaskingGray2D()

      Input:  pixs (8 bpp; no colormap)
              halfwidth  ("half-width" of smoothing filter: 1 or 2)
              fract  (fraction of high frequency added to image)
      Return: pixd, or null on error

  Notes:
      (1) For halfwidth == 1, we implement the full sharpening filter
          directly.  For halfwidth == 2, we implement the the lowpass
          filter separably and then compute the sharpening result locally.
      (2) Returns a clone if no sharpening is requested.

=head2 pixUnsharpMaskingGrayFast

PIX * pixUnsharpMaskingGrayFast ( PIX *pixs, l_int32 halfwidth, l_float32 fract, l_int32 direction )

  pixUnsharpMaskingGrayFast()

      Input:  pixs (8 bpp; no colormap)
              halfwidth  ("half-width" of smoothing filter: 1 or 2)
              fract  (fraction of high frequency added to image)
              direction (L_HORIZ, L_VERT, L_BOTH_DIRECTIONS)
      Return: pixd, or null on error

  Notes:
      (1) For usage and explanation of the algorithm, see notes
          in pixUnsharpMaskingFast().
      (2) Returns a clone if no sharpening is requested.

=cut

1;