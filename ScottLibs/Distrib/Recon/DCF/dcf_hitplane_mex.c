/**************************************************************************
 *  DCF_HITPLANE_MEX.C
 *
 *  Author: Scott Haile Robertson
 *  Website: www.ScottHaileRobertson.com
 *  Date: February 12, 2013
 *
 *  A MATLAB mex wrapper for N-Dimmensional hitplane DCF calculation.
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
#include "dcf_hitplane.c"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){
    
    /* Definitions */
    double *coords;                     // Array of coordinates (each column is a dimmension)
    double kernel_width;                // Convolution kernel width
    unsigned int kernel_length;         // Length of kernel_vals lookup table
    const unsigned int *output_dims;    // Size of output dimensions
    const unsigned int *dims;           // Dimension vector [#pts, #dimmensions]
    unsigned int ndims;                 // Number of dimensions sampled
    unsigned int npts;                  // Total number of points sampled
    double *dcf;
    
    /* FOR DEBUG ONLY */
//     #define DEBUG 1;
    #ifdef DEBUG
        unsigned int i;
        int dim2;
    #endif
    
    
    /* CHECK INPUT ARGUMENT COUNT *
     * REQUIRED: coords, kernel_width, output_dimss */
    if (nrhs != 3) {
        mexErrMsgTxt("Required inputs: coords, kernel_width, output_dims.");
    }
    
    
    /* CHECK OUTPUT ARGUMENT COUNT *
     * REQUIRED: grid_volume  */
    if (nlhs != 1) {
        mexErrMsgTxt("Exactly 1 output (dcf) is returned.");
    }
  
    
    /* INPUT 0 - COORDINATES - can be 2D, 3D, 4D, and beyond */
    mxAssert(!mxIsEmpty(prhs[0]),"coords cannot be null.");
    mxAssert(mxIsDouble(prhs[0]), "coords must be of type double");
    mxAssert(mxGetNumberOfDimensions(prhs[0]) == 2, "coords must be a 2D array (each dimmension is a column)");
    dims = (unsigned int *) mxGetDimensions(prhs[0]);           // get dimension vector
    ndims = (unsigned int) dims[0];                             // number of dimensions
    npts  = (unsigned int) dims[1];                             // number of points
    coords = mxGetPr(prhs[0]);                                  // coordinates
    
    
    /* INPUT 1 - KERNEL WIDTH */
    mxAssert(!mxIsEmpty(prhs[1]),"kernel_width cannot be null.");
    mxAssert(mxIsDouble(prhs[1]), "kernel_width must be of type double.");
    mxAssert(mxGetNumberOfDimensions(prhs[1]) == 2, "kernel_width has wrong number of dimmensions (should be just a double value).");
    mxAssert(mxGetDimensions(prhs[1])[0] == 1, "kernel_width must be a double value, not an array.");
    mxAssert(mxGetDimensions(prhs[1])[1] == 1, "kernel_width must be a double value, not an array.");
    kernel_width = *mxGetPr(prhs[1]);                           // kernel_width
    
    
    /* INPUT 2 - OUTPUT VOLUME DIMS - Used to create output volume */
    mxAssert(!mxIsEmpty(prhs[2]),"vol_dims cannot be null.");
    mxAssert(mxIsUint32(prhs[2]), "vol_dims must be of type uint32.");
    mxAssert(mxGetNumberOfDimensions(prhs[2]) == 2, "vol_dims has the wrong number of dimmensions (should be a row vector).");
    mxAssert(mxGetDimensions(prhs[2])[0] == 1, "vol_dims must be a vector.");
    mxAssert(mxGetDimensions(prhs[2])[1] == ndims, "there must be the same number of vol_dims as dimmensions.");
    output_dims = (unsigned int *) mxGetPr(prhs[2]);            // output dimensions
    
    
    /* OUTPUT 0 - GRIDDED KSPACE - Created with dimensions of output_dims */
    plhs[0] = mxCreateNumericArray(ndims,output_dims,mxDOUBLE_CLASS,mxREAL); // output
    mxAssert(!mxIsEmpty(prhs[0]),"Output matrix was not allocated correctly. Possibly out of memory.");
    dcf = mxGetData(plhs[0]);
    
    
    /* DEBUG PRINTING */
    #ifdef DEBUG
        mexPrintf("ndims=%i\n",ndims);
        mexPrintf("npts=%i\n\n",npts);

        mexPrintf("Input coords:\n");
        for(i=0; i<npts; i++){
            mexPrintf("\tCoords[%u]=(%f,%f,%f)\n",i,coords[3*i],coords[3*i+1],coords[3*i+2]);
        }
        mexPrintf("End of input coords.\n\n");


        mexPrintf("Kernel width=:%f\n\n",kernel_width);

        mexPrintf("Input output_dims:\n");
        for(i=0; i<ndims; i++){
            mexPrintf("\toutput_dims[%u]=%u\n",i,output_dims[i]);
        }
        mexPrintf("End of ouput_dims.\n\n");
    #endif 
            
    /* Perform the convolution based gridding */
    dcf_hitplane(coords, &kernel_width, &kernel_length, &npts, &ndims, output_dims, dcf);
}


