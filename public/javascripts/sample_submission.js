$(document).ready(function() {

  $('#js_enabled').show();
  $('#js_disabled').hide();

  $.validator.addMethod("noSpaces", function(value, element) {
    return !/\s/.test(value);
  }, "No spaces are allowed in this field");

  $(function(){
    $("form").formwizard({ 
      formPluginEnabled: true,
      validationEnabled: true,
      focusFirstInput : true,
      formOptions :{
        success: function(data){
          $('#error').hide();
          $('form').hide();
          $('#success').show();
        },
        error: function(data) { submissionError(data); },
        beforeSubmit: function(data){$("#data").html("data sent to the server: " + $.param(data));},
        dataType: 'json',
      },
      inDuration : 200,
      outDuration: 200
    });
  });

  function submissionError(data) {
    $('#ErrorExplanation>p').replaceWith( '<p>' + JSON.parse(data.responseText).message + '</p>');
    $('#ErrorExplanation').show();
  }

  // generate the sample mixture fields
  //$('input[type=submit]').click(function() {
  //});
  $('form').bind('step_shown', function(event, data) {
    if(data.currentStep == "samples") {
      generate_mixture_form();
    }
    if(data.previousStep == "samples") {
      remove_mixture_form();
    }
  });

  function generate_mixture_form() {
    var project_id, number_of_samples, multiplexing_scheme_id, naming_scheme_id, params;

    project_id = $('#sample_set_project_id').attr('value');
    naming_scheme_id = $('#sample_set_naming_scheme_id').attr('value');
    number_of_samples = $('#sample_set_number').attr('value');
    multiplexing_scheme_id = $('.step:visible > p > select.multiplexing_scheme_id').attr('value');
    multiplexed_number = $('#sample_set_multiplexed_number').attr('value');

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
        sample_set: params
      },
      type: 'GET',
      success : function(data){
        $('#sample_mixture_fields').replaceWith(data);
        return true; //return true to make the wizard move to the next step
      }
    });
  }

  function remove_mixture_form() {
    $('#sample_mixture_fields').replaceWith('<div id="sample_mixture_fields"></div>');
  }

  $('#sample_set_sample_prep_kit_id').change(function() {
    set_default_primer();
    setup_fields();
  });

  $('#sample_set_primer_id').change(function() {
    setup_fields();
  });

  $('#sample_set_read_format').change(function() {
    set_default_primer();
    setup_fields();
  });

  $('#sample_set_desired_read_length').change(function() {
    setup_fields();
  });

  $('#sample_set_desired_read_length_1').change(function() {
    setup_fields();
  });

  $('#sample_set_desired_read_length_2').change(function() {
    setup_fields();
  });

  $('.multiplexing_scheme_id').change(function() {
    set_default_primer();
    setup_fields();
  });

  $('#sample_set_custom_prep_kit_id').change(function() {
    setup_fields();
  });

  $('#sample_set_custom_prep_kit_name').change(function() {
    setup_fields();
  });

  $('#sample_set_custom_primer_id').change(function() {
    setup_fields();
  });

  $('#sample_set_custom_primer_name').change(function() {
    setup_fields();
  });

  function set_genomic_primer() {
    primer_id = $('option:contains(Genomic primer)').attr('value');
    $('#sample_set_primer_id').attr('value', primer_id);
  }

  function set_default_primer() {
    var kit_id = $('#sample_set_sample_prep_kit_id').attr('value');
    $('#sample_set_primer_id').attr('value', default_primers[kit_id]);
  }

  function setup_fields() {
    if( $('#sample_set_sample_prep_kit_id').attr('value') === "-1" ) {
      $('#custom_prep').show();
      $('#sample_set_custom_prep_kit_id').addClass('required');
    }
    else {
      $('#custom_prep').hide();
      $('#sample_set_custom_prep_kit_id').removeClass('required');
    }

    if( $('#sample_set_custom_prep_kit_name').attr('value') === '' && $('#sample_set_sample_prep_kit_id').attr('value') === "-1") {
      $('#sample_set_custom_prep_kit_id').addClass('required');
    }
    else {
      $('#sample_set_custom_prep_kit_id').removeClass('required');
    }

    if( $('#sample_set_primer_id').attr('value') == "-1" ) {
      $('#custom_primer').show();
      $('#sample_set_custom_primer_id').addClass('required');
    }
    else {
      $('#custom_primer').hide();
      $('#sample_set_custom_primer_id').removeClass('required');
    }

    if( $('#sample_set_custom_primer_name').attr('value') === '' && $('#sample_set_primer_id').attr('value') == "-1" ) {
      $('#sample_set_custom_primer_id').addClass('required');
    }
    else {
      $('#sample_set_custom_primer_id').removeClass('required');
    }

    if( $('#sample_set_read_format').attr('value') == "Single read" ) {
      $('#single_read').show();
      $('#paired_end').hide();
      $('#sample_set_desired_read_length,#sample_set_alignment_start_position,#sample_set_alignment_end_position').addClass('required');
      $('#sample_set_desired_read_length_1,#sample_set_alignment_start_position_1,#sample_set_alignment_end_position_1').removeClass('required');
      $('#sample_set_desired_read_length_2,#sample_set_alignment_start_position_2,#sample_set_alignment_end_position_2').removeClass('required');
    }
    else if( $('#sample_set_read_format').attr('value') == "Paired end" ) {
      $('#single_read').hide();
      $('#paired_end').show();
      $('#sample_set_desired_read_length,#sample_set_alignment_start_position,#sample_set_alignment_end_position').removeClass('required');
      $('#sample_set_desired_read_length_1,#sample_set_alignment_start_position_1,#sample_set_alignment_end_position_1').addClass('required');
      $('#sample_set_desired_read_length_2,#sample_set_alignment_start_position_2,#sample_set_alignment_end_position_2').addClass('required');
      set_genomic_primer();
    }
    else {
      $('#single_read').hide();
      $('#paired_end').hide();
    }

    if( $('.multiplexing_scheme_id').attr('value') === "" ) {
      $('#multiplexing').hide();
      $('#sample_set_multiplexed_number').removeClass('required');
    }
    else {
      $('#multiplexing').show();
      $('#sample_set_multiplexed_number').addClass('required');
      set_genomic_primer();
    }

    $('#sample_set_alignment_end_position').attr('value', $('#sample_set_desired_read_length').attr('value'));
    $('#sample_set_alignment_end_position_1').attr('value', $('#sample_set_desired_read_length_1').attr('value'));
    $('#sample_set_alignment_end_position_2').attr('value', $('#sample_set_desired_read_length_2').attr('value'));
  }

  setup_fields();

  $('#add_custom_prep').click(function() {
    $('#new_custom_prep_kit').toggle();
  });

  $('#add_custom_primer').click(function() {
    $('#new_custom_primer').toggle();
  });
});
