function set_alignment_end_position(value) {
  $('sample_set_alignment_end_position').value = value;
}

function toggle_search_criteria() {
  $('search_criteria_hidden').toggle()
  $('search_criteria_shown').toggle()
}

function toggle_sample_approval(elem) {
  e = Event.element(elem);
  html_id = e.id;
  sample_id = html_id.match(/.*\-(\d+)/)[1];
  checked = e.checked;
  url = '/samples/' + sample_id + ".json"
  params = 'sample[0][ready_for_sequencing]=' + checked
  new Ajax.Request(
    url, {
      method: 'put',
      parameters: params,
      onLoading: function(req) {
        Element.show('sample_approval-'+sample_id+'-loading');
        $$('.sample_approval').invoke('disable');
      },
      onComplete: function(req) {
        $$('.sample_approval').invoke('enable');
        Element.hide('sample_approval-'+sample_id+'-loading');
      }
    }
  );
}

// Register the onclick event for all sample approval checkboxes  
window.onload = function() {  
  $$('.sample_approval').invoke('observe', 'click', toggle_sample_approval);
}  

