#include <math.h>
#include <stdio.h>

/**************************************************************************
 *  GRID_CONV.C
 *
 *  Author: Scott Haile Robertson
 *  Website: www.ScottHaileRobertson.com
 *  Date: June 4, 2012
 *
 *  An N-Dimmensional convolution based gridding algorithm. Motivated by 
 *  code written by Gary glover 
 *  (http://www-mrsrl.stanford.edu/~brian/gridding/) 
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

/* In case c math.h libraries dont have min, max, and round defined, we'll define them. */
#ifndef min
double min(double a, double b) {
    return ((a < b) ? a : b);
}
#endif

#ifndef max
double max(double a, double b) {
    return ((a > b) ? a : b);
}
#endif

#ifndef round
int round(double num) {
    return (num < 0.0) ? ceil(num - 0.5) : floor(num + 0.5);
}
#endif

/* Recursive function that loops through a bounded section of the output *
 * grid, convolving the ungridded point's data according to the provided *
 * convolution kernel, density compensation value, and the ungridded     *
 * point's value. The recursion allows for n-dimmensional data           *
 * reconstruction.                                                       */
void grid_point(double *sample_loc, unsigned int *idx_convert, double pt_r, 
        double pt_i, double *kernel_vals, double kernel_halfwidth_sqr, 
        double index_multiplier, unsigned int *ndims,
        unsigned int cur_dim, unsigned int *bounds, unsigned int *seed_pt,
        double kern_dist_sq, const unsigned int *output_dims,
        double *grid_r, double *grid_i){
    
    /* DEFINITIONS */
    unsigned int i;
    unsigned int j;
    unsigned int lower;
    unsigned int upper;
    unsigned int idx_;
    unsigned int kern_idx;
    double new_kern_dist_sq;
    
    lower = bounds[2 * cur_dim];
    upper = bounds[2 * cur_dim + 1];
    
    for(i = lower; i<=upper; i++){
        /* UPDATE SEED PT FOR RECURSIVE LOOPS */
        seed_pt[cur_dim]=i;
        
        new_kern_dist_sq = ((double)i-sample_loc[cur_dim]);
        new_kern_dist_sq *= new_kern_dist_sq; // square it
        new_kern_dist_sq += kern_dist_sq;     // add to growing sum
        
        /* RECURSE THROUGH OTHER DIMMENSIONS */
        if(cur_dim > 0){
            grid_point(sample_loc, idx_convert, pt_r, pt_i, kernel_vals, kernel_halfwidth_sqr, index_multiplier, ndims, cur_dim-1,
                    bounds, seed_pt, new_kern_dist_sq, output_dims,
                    grid_r, grid_i);
        }else{
            /* THIS IS THE SMALLEST DIMMENSION, SO GRID! */
            if(new_kern_dist_sq <= kernel_halfwidth_sqr){ 
                
                /* CALCULATE INDEX FROM X,Y,Z COORDINATES */
                idx_ = 0;//seed_pt[0];
                for(j=0; j<*ndims; j++){
                    idx_ = idx_ + (seed_pt[j])*idx_convert[j];
                }

                /* CALCULATE KERNEL INDEX*/
                kern_idx = (unsigned int)round(round(index_multiplier*new_kern_dist_sq));
                
                grid_r[idx_]+=pt_r*kernel_vals[kern_idx];
                grid_i[idx_]+=pt_i*kernel_vals[kern_idx];
            }
        }
        
        /* RESET THIS DIMENSION */
        seed_pt[cur_dim]=lower;
    }
}

/* Performs convolution based gridding. Loops through a set of 
 * n-dimensionalsample points and convolves them onto a grid. */
void grid_conv(double *data, double *coords, double *kernel_width,
        double *kernel_vals, unsigned int *kernel_length, unsigned int *npts, unsigned int *ndims,
        const unsigned int *output_dims, double *grid_r, double *grid_i){
    
    /* DEFINITIONS */
    unsigned int *seed_pt;	// seed indices within subarray recursion loops
    unsigned int dim;       // dimmension loop index variable
    unsigned int p;         // point loop index variable
    unsigned int *bounds;   // array defining mininum and maximum boundaries of subarray
    double *sample_loc;
    unsigned int *output_halfwidth;
    double index_multiplier;
    unsigned int *idx_convert;
    double kernel_halfwidth;
    double kernel_halfwidth_sqr;
    unsigned int n_vox = 1;
    
    /* CALCULATE KERNEL HALFWIDTH AND OUTPUT_HALFWIDTH */
    kernel_halfwidth = *kernel_width/(double)2.0;
    kernel_halfwidth_sqr = kernel_halfwidth * kernel_halfwidth;
    index_multiplier = (*kernel_length - 1) / (kernel_halfwidth_sqr); //When you multiply this by the radius, it gives the kernel index
    output_halfwidth = calloc(*ndims, sizeof(unsigned int));
    if(output_halfwidth == NULL){printf("Error allocating memory for output_halfwidth. Crashing... :)\n");}
        
    for(dim=0; dim<*ndims; dim++){
        output_halfwidth[dim] = (unsigned int) ceil(((double)output_dims[dim])*0.5);
    }
    
    /* ALLOCATE MEMORY FOR SUBARRAY BOUNDARIES, RECURSIVE SEED INDICES   *
     * AND SAMPLE LOCATION ARRAY                                         */
    bounds = calloc(2 * *ndims, sizeof(unsigned int));
    seed_pt = calloc(*ndims, sizeof(unsigned int));
    sample_loc = calloc(*ndims, sizeof(double));
    idx_convert = calloc(*ndims, sizeof(unsigned int));
    if(bounds      == NULL){printf("Error allocating memory for bounds. Crashing... :)\n");}
    if(seed_pt     == NULL){printf("Error allocating memory for seed_pt. Crashing... :)\n");}
    if(sample_loc  == NULL){printf("Error allocating memory for sample_loc. Crashing... :)\n");}
    if(idx_convert == NULL){printf("Error allocating memory for idx_convert. Crashing... :)\n");}
    
    /* CALCULATE X, Y, Z TO INDEX CONVERSIONS */
    for(dim=0; dim<*ndims; dim++){
        idx_convert[dim] = 1;
        if(dim>0){
            for(p=0; p<dim; p++){
                idx_convert[dim] = idx_convert[dim] * output_dims[p];
            }
        }
    }
    
    /* LOOP THROUGH SAMPLE POINTS */
    for (p=0; p<*npts; p++){
        
        /* CALCULATE SUBARRAY BOUNDARIES */
        for(dim=0; dim<*ndims; dim++){
            sample_loc[dim] = (coords[*ndims*p+dim]*(double)output_dims[dim]+(double)output_halfwidth[dim]); // Convert to voxel space indices - zero is upper left hand corner
            
            /* CALCULATE BOUNDS */
            bounds[2*dim] = (unsigned int) max(ceil(sample_loc[dim]-kernel_halfwidth),0);                   // Lower boundary
            bounds[2*dim+1] = (unsigned int) min(floor(sample_loc[dim]+kernel_halfwidth),output_dims[dim]-1);  // Upper boundary
            
            /* INITIALIZE RECURSIVE SEED POINT AS UPPER LEFT CORNER OF SUBARRAY */
            seed_pt[dim] = bounds[2*dim];
        }
       
        grid_point(sample_loc, idx_convert, data[2*p], data[2*p+1], kernel_vals, kernel_halfwidth_sqr, index_multiplier, ndims, *ndims-1, bounds,
                seed_pt, 0, output_dims, grid_r, grid_i);
    }
        
    /* Free up some memory */
    free(bounds);
    free(seed_pt);
    free(output_halfwidth);
}

