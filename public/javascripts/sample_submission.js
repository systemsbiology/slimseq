$(document).ready(function() {
  $(function(){
    $("form").formwizard({ 
      formPluginEnabled: true,
      validationEnabled: true,
      focusFirstInput : true,
      formOptions :{
        success: function(data){$("#status").fadeTo(500,1,function(){ $(this).html("You are now registered!").fadeTo(5000, 0); })},
        beforeSubmit: function(data){$("#data").html("data sent to the server: " + $.param(data));},
        dataType: 'json',
        resetForm: true
      },
      inDuration : 200,
      outDuration: 200
     }
    );
  });

  $('input[type=submit]').click(function() {
    if( $('#1:visible,#2:visible').length > 0 ) {
      var project_id, number_of_samples, multiplexing_scheme_id, naming_scheme_id, params;

      project_id = $('#samples_project_id').attr('value');
      naming_scheme_id = $('#samples_naming_scheme_id').attr('value');
      number_of_samples = $('#samples_number').attr('value');
      multiplexing_scheme_id = $('.step:visible > p > select.multiplexing_scheme_id').attr('value');
      multiplexed_number = $('#samples_multiplexed_number').attr('value');

      params = {};
      if(project_id && project_id !== "") params["project_id"] = project_id;
      if(naming_scheme_id && naming_scheme_id !== "") params["naming_scheme_id"] = naming_scheme_id;
      if(number_of_samples) params["number_of_samples"] = number_of_samples;
      if(multiplexing_scheme_id) {
        params["multiplexing_scheme_id"] = multiplexing_scheme_id;
        params["samples_per_mixture"] = multiplexed_number || 1;
      }else {
        params["samples_per_mixture"] = 1;
      }

      $.ajax({ // add a remote ajax call when moving next from the second step
        url : "sample_mixture_fields", 
        dataType : 'html',
        data: {
          samples: params
        },
        type: 'GET',
        //beforeSend : function(){alert("Starting validation.")},
        //complete : function(){alert("Validation complete.")},
        success : function(data){
          $('#sample_mixture_fields').replaceWith(data);
          return true; //return true to make the wizard move to the next step
        }
      });
    }
  });

  $('#samples_sample_prep_kit_id').change(function() {
    setup_fields();
  });

  $('#samples_primer_id').change(function() {
    setup_fields();
  });

  $('#samples_read_format').change(function() {
    setup_fields();
  });

  $('#samples_desired_read_length').change(function() {
    setup_fields();
  });

  $('#samples_desired_read_length_1').change(function() {
    setup_fields();
  });

  $('#samples_desired_read_length_2').change(function() {
    setup_fields();
  });

  $('.multiplexing_scheme_id').change(function() {
    setup_fields();
  });

  $('#samples_custom_prep_kit_id').change(function() {
    setup_fields();
  });

  $('#samples_custom_prep_kit_name').change(function() {
    setup_fields();
  });

  $('#samples_custom_primer_id').change(function() {
    setup_fields();
  });

  $('#samples_custom_primer_name').change(function() {
    setup_fields();
  });

  function setup_fields() {
    if( $('#samples_sample_prep_kit_id').attr('value') === "-1" ) {
      $('#custom_prep').show();
      $('#samples_custom_prep_kit_id').addClass('required');
    }
    else {
      $('#custom_prep').hide();
      $('#samples_custom_prep_kit_id').removeClass('required');
    }

    if( $('#samples_custom_prep_kit_name').attr('value') === '' && $('#samples_sample_prep_kit_id').attr('value') === "-1") {
      $('#samples_custom_prep_kit_id').addClass('required');
    }
    else {
      $('#samples_custom_prep_kit_id').removeClass('required');
    }

    if( $('#samples_primer_id').attr('value') == "-1" ) {
      $('#custom_primer').show();
      $('#samples_custom_primer_id').addClass('required');
    }
    else {
      $('#custom_primer').hide();
      $('#samples_custom_primer_id').removeClass('required');
    }

    if( $('#samples_custom_primer_name').attr('value') === '' && $('#samples_primer_id').attr('value') == "-1" ) {
      $('#samples_custom_primer_id').addClass('required');
    }
    else {
      $('#samples_custom_primer_id').removeClass('required');
    }

    if( $('#samples_read_format').attr('value') == "Single read" ) {
      $('#single_read').show();
      $('#paired_end').hide();
      $('#samples_desired_read_length,#samples_alignment_start_position,#samples_alignment_end_position').addClass('required');
      $('#samples_desired_read_length_1,#samples_alignment_start_position_1,#samples_alignment_end_position_1').removeClass('required');
      $('#samples_desired_read_length_2,#samples_alignment_start_position_2,#samples_alignment_end_position_2').removeClass('required');
    }
    else if( $('#samples_read_format').attr('value') == "Paired end" ) {
      $('#single_read').hide();
      $('#paired_end').show();
      $('#samples_desired_read_length,#samples_alignment_start_position,#samples_alignment_end_position').removeClass('required');
      $('#samples_desired_read_length_1,#samples_alignment_start_position_1,#samples_alignment_end_position_1').addClass('required');
      $('#samples_desired_read_length_2,#samples_alignment_start_position_2,#samples_alignment_end_position_2').addClass('required');
    }
    else {
      $('#single_read').hide();
      $('#paired_end').hide();
    }

    if( $('.multiplexing_scheme_id').attr('value') === "" ) {
      $('#multiplexing').hide();
    }
    else {
      $('#multiplexing').show();
    }

    $('#samples_alignment_end_position').attr('value', $('#samples_desired_read_length').attr('value'));
    $('#samples_alignment_end_position_1').attr('value', $('#samples_desired_read_length_1').attr('value'));
    $('#samples_alignment_end_position_2').attr('value', $('#samples_desired_read_length_2').attr('value'));
  }

  setup_fields();

  $('#add_custom_prep').click(function() {
    $('#new_custom_prep_kit').toggle();
  });

  $('#add_custom_primer').click(function() {
    $('#new_custom_primer').toggle();
  });
});
