/**************************************************************************
 *  GRID_CONV_MEX.C
 *
 *  Author: Scott Haile Robertson
 *  Website: www.ScottHaileRobertson.com
 *  Date: June 4, 2012
 *
 *  A MATLAB mex wrapper for N-Dimmensional gridding. Motivated by code 
 *  written by Gary glover (http://www-mrsrl.stanford.edu/~brian/gridding/) 
 *  and also from code by Nick Zwart.
 *
 *  For background reading, I suggest:
 *      1. A fast Sinc Function Gridding Algorithm for Fourier Inversion in
 *         Computer Tomography. O'Sullivan. 1985.
 *      2. Selection of a Convolution Function for Fourier Inversion using
 *         Gridding. Jackson et al. 1991.
 *      3. Rapid Gridding Reconstruction With a Minimal Oversampling Ratio. 
 *         Beatty et al. 2005.
 *
 *  NOTE: compiling in debug mode (mex -g grid_conv_mex.c) turns on error
 *        checking of inputs. I recommend that you compile in debug mode
 *        to ensure that you are passing input arguments correctly, then
 *        recompile without debug mode once you have it wired correctly and
 *        enjoy the speed.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  This code
 *  is for research and academic purposes and is not intended for
 *  clinical use.
 *
 **************************************************************************/
#include "mex.h"
#include "grid_conv.c"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){
    
    /* Definitions */
    double *coords;                     // Array of coordinates (each column is a dimmension)
    double *data;                       // Array of data (real and imaginary parts are separate rows)
    double kernel_width;                // Convolution kernel width
    double *kernel_vals;                // Convolution kernel lookup table
    unsigned int kernel_length;         // Length of kernel_vals lookup table
    const unsigned int *output_dims;    // Size of output dimensions
    const unsigned int *dims;           // Dimension vector [#pts, #dimmensions]
    unsigned int ndims;                 // Number of dimensions sampled
    unsigned int npts;                  // Total number of points sampled
    double *grid_r;
    double *grid_i;
    
    /* FOR DEBUG ONLY */
    //#define DEBUG 1;
    #ifdef DEBUG
        unsigned int i;
        int dim2;
    #endif
    
    
    /* CHECK INPUT ARGUMENT COUNT *
     * REQUIRED: data, coords, weight, effMtx, numThreads */
    if (nrhs != 5) {
        mexErrMsgTxt("Required inputs: data, coords, kernel_width, kernel values, output_dims.");
    }
    
    
    /* CHECK OUTPUT ARGUMENT COUNT *
     * REQUIRED: grid_volume  */
    if (nlhs != 1) {
        mexErrMsgTxt("Exactly 1 output (grid_volume) is returned.");
    }
    
    /* 0 - DATA - Must be 2D double array (real and imaginary are rows) */
    mxAssert(!mxIsEmpty(prhs[0]), "data cannot be null.");
    mxAssert(mxIsDouble(prhs[0]), "data must be of type double.");
    mxAssert(mxGetNumberOfDimensions(prhs[0]) == 2, "data must be a 2D matrix.");
    mxAssert(mxGetDimensions(prhs[0])[0] == 2, "data must have exatcly 2 rows (real/imag parts).");
    data = mxGetPr(prhs[0]);                                    // data
    
    
    /* INPUT 1 - COORDINATES - can be 2D, 3D, 4D, and beyond */
    mxAssert(!mxIsEmpty(prhs[1]),"coords cannot be null.");
    mxAssert(mxIsDouble(prhs[1]), "coords must be of type double");
    mxAssert(mxGetNumberOfDimensions(prhs[1]) == 2, "coords must be a 2D array (each dimmension is a column)");
    dims = (unsigned int *) mxGetDimensions(prhs[1]);           // get dimension vector
    ndims = (unsigned int) dims[0];                             // number of dimensions
    npts  = (unsigned int) dims[1];                             // number of points
    coords = mxGetPr(prhs[1]);                                  // coordinates
    
    /* Check that data size is twice npts (real and imag) */
    mxAssert(mxGetDimensions(prhs[0])[1] == npts, "there must be the same number of data values as coords.");
    
    
    /* INPUT 2 - KERNEL WIDTH */
    mxAssert(!mxIsEmpty(prhs[2]),"kernel_width cannot be null.");
    mxAssert(mxIsDouble(prhs[2]), "kernel_width must be of type double.");
    mxAssert(mxGetNumberOfDimensions(prhs[2]) == 2, "kernel_width has wrong number of dimmensions (should be just a double value).");
    mxAssert(mxGetDimensions(prhs[2])[0] == 1, "kernel_width must be a double value, not an array.");
    mxAssert(mxGetDimensions(prhs[2])[1] == 1, "kernel_width must be a double value, not an array.");
    kernel_width = *mxGetPr(prhs[2]);                           // kernel_width
    
    
    /* INPUT 3 - KERNEL VALUE LOOKUP TABLE */
    mxAssert(!mxIsEmpty(prhs[3]),"kernel_vals cannot be null.");
    mxAssert(mxIsDouble(prhs[3]), "kernel_vals must be of type double.");
    mxAssert(mxGetNumberOfDimensions(prhs[3]) == 2, "kernel_vals has wrong number of dimmensions (should be a row vector).");
    mxAssert(mxGetDimensions(prhs[3])[0] == 1, "kernel_vals must be a row vector.");
    mxAssert(mxGetDimensions(prhs[3])[1] > 1, "there must be at least 2 kernel_vals in lookup table for interpolation.");
    kernel_length = (unsigned int) mxGetDimensions(prhs[3])[1]; // kernel_length
    kernel_vals = mxGetPr(prhs[3]);                             // kernel_vals
    
    
    /* INPUT 4 - OUTPUT VOLUME DIMS - Used to create output volume */
    mxAssert(!mxIsEmpty(prhs[4]),"vol_dims cannot be null.");
    mxAssert(mxIsUint32(prhs[4]), "vol_dims must be of type uint32.");
    mxAssert(mxGetNumberOfDimensions(prhs[4]) == 2, "vol_dims has the wrong number of dimmensions (should be a row vector).");
    mxAssert(mxGetDimensions(prhs[4])[0] == 1, "vol_dims must be a vector.");
    mxAssert(mxGetDimensions(prhs[4])[1] == ndims, "there must be the same number of vol_dims as dimmensions.");
    output_dims = (unsigned int *) mxGetPr(prhs[4]);            // output dimensions
    
    
    /* OUTPUT 1 - GRIDDED KSPACE - Created with dimensions of output_dims */
    plhs[0] = mxCreateNumericArray(ndims,output_dims,mxDOUBLE_CLASS,mxCOMPLEX); // output
    mxAssert(!mxIsEmpty(prhs[0]),"Output matrix was not allocated correctly. Possibly out of memory.");
    grid_r = mxGetPr(plhs[0]);
    grid_i = mxGetPi(plhs[0]);
    
    
    /* DEBUG PRINTING */
    #ifdef DEBUG
        mexPrintf("ndims=%i\n",ndims);
        mexPrintf("npts=%i\n\n",npts);

        mexPrintf("Input data:\n");
        for(i=0; i<npts; i++){
            mexPrintf("\tData[%u]=(%f,%f)\n",i,data[2*i],data[2*i+1]);
        }
        mexPrintf("End of input data.\n\n");

        mexPrintf("Input coords:\n");
        for(i=0; i<npts; i++){
            mexPrintf("\tCoords[%u]=(%f,%f,%f)\n",i,coords[3*i],coords[3*i+1],coords[3*i+2]);
        }
        mexPrintf("End of input coords.\n\n");


        mexPrintf("Kernel width=:%f\n\n",kernel_width);

        mexPrintf("Input kernel_vals:\n");
        for(i=0; i<kernel_length; i++){
            mexPrintf("\tkernel_vals[%f]=%f\n",i,kernel_vals[i]);
        }
        mexPrintf("End of kernel_vals.\n\n");


        mexPrintf("Input output_dims:\n");
        for(i=0; i<ndims; i++){
            mexPrintf("\toutput_dims[%u]=%u\n",i,output_dims[i]);
        }
        mexPrintf("End of ouput_dims.\n\n");
    #endif 
            
    /* Perform the convolution based gridding */
    grid_conv(data, coords, &kernel_width, kernel_vals, &kernel_length, &npts, &ndims, output_dims, grid_r, grid_i);
}


