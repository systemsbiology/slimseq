
  // Path to the blank image must point to a valid location on your server
  Ext.BLANK_IMAGE_URL = site_url + '/ext/resources/images/default/s.gif';
 
  // Main application entry point
  Ext.onReady(function() {
      var Tree = Ext.tree;
 
      tree = new Tree.TreePanel({
        el:'tree_div',
	    useArrows:true,
	    autoScroll:true,
	    animate:true,
	    enableDD:false,
	    containerScroll: true,
 
	    dataUrl: '../projects/explore_data',
 
	    root: {
              nodeType  : 'async',
	      text      : 'Projects',
	      visible   : false,
	      id        : 'source'
	      }
	});
 
      // render the tree and expand the parent node
      tree.render();
      tree.getRootNode().expand();
    });
