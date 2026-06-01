/*
 * FIJI script to run BigStitcher
 * david.barry@crick.ac.uk
 * 2026.06.01
 */

macro "Run_BigStitcher"{
	setBatchMode(true);
	args = split(getArgument(), ",");
	
	// Convert relative paths to absolute paths to satisfy BigStitcher/Java URIs
	input = File.getAbsolutePath(args[0]);
	output = File.getAbsolutePath(args[1]);
	
	if(!File.exists(input)){
		IJ.log("Invalide input path: " + input);
		IJ.log("Exiting");
		exit();
	}
	if(!File.exists(output)){
		IJ.log("Invalide output path: " + output);
		IJ.log("Exiting");
		exit();
	}
	
	project_filename = File.getName(input) + "_dataset.xml";
	print("Defining new dataset " + project_filename);
	print("Reading input files from " + input);
	print("Output will be saved in " + output);
	run("Define Multi-View Dataset", "define_dataset=[Automatic Loader (Bioformats based)] project_filename=" + project_filename + " path=" + input + " exclude=10 bioformats_series_are?=Tiles bioformats_channels_are?=Channels pattern_0=[-- ignore this pattern --] pattern_1=[-- ignore this pattern --] move_tiles_to_grid_(per_angle)?=[Do not move Tiles to Grid (use Metadata if available)] how_to_store_input_images=[Re-save as multiresolution HDF5] load_raw_data_virtually metadata_save_path=" + output + " image_data_save_path=" + output + " check_stack_sizes subsampling_factors=[{ {1,1,1}, {2,2,2}, {4,4,4} }] hdf5_chunk_sizes=[{ {16,16,16}, {32,16,8}, {64,32,2} }] timepoints_per_partition=1 setups_per_partition=0 use_deflate_compression");
	project_filepath = output + File.separator() + project_filename;
	run("Calculate pairwise shifts ...", "select=file:" + project_filepath + " process_angle=[All angles] process_channel=[All channels] process_illumination=[All illuminations] process_tile=[All tiles] process_timepoint=[All Timepoints] method=[Phase Correlation] show_expert_algorithm_parameters channels=[Average Channels] downsample_in_x=2 downsample_in_y=2 downsample_in_z=2 number_of_peaks_to_check=5 minimal_overlap=0 subpixel_accuracy");
	run("Filter pairwise shifts ...", "select=file:" + project_filepath + " filter_by_link_quality min_r=0.2 max_r=1 max_shift_in_x=0 max_shift_in_y=0 max_shift_in_z=0 max_displacement=0");
	run("Optimize globally and apply shifts ...", "select=file:" + project_filepath + " process_angle=[All angles] process_channel=[All channels] process_illumination=[All illuminations] process_tile=[All tiles] process_timepoint=[All Timepoints] relative=2.500 absolute=3.500 global_optimization_strategy=[Two-Round using Metadata to align unconnected Tiles and iterative dropping of bad links] pre-align");
	run("Image Fusion", "select=file:" + project_filepath + " process_angle=[All angles] process_channel=[All channels] process_illumination=[All illuminations] process_tile=[All tiles] process_timepoint=[All Timepoints] bounding_box=[All Views] downsampling=1 interpolation=[Linear Interpolation] fusion_type=[Avg, Blending] pixel_type=[16-bit unsigned integer] interest_points_for_non_rigid=[-= Disable Non-Rigid =-] produce=[Each timepoint & channel] fused_image=[Save as (compressed) TIFF stacks] define_input=[Auto-load from input data (values shown below)] output_file_directory=" + output + " filename_addition=fused");
	setBatchMode(false);
}