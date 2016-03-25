			

libLFM.setApiKey('9e67d33d183909be617217ecbecade37');

/**
 * Object describing the view
 */
var view = (function () {

    // private
    var _private = {
    	artistInputContentId: 		'#artistInputCont',
        artistInputId: 				'#artistInput',
        userInputId: 				'#userInput',
        resultsId:					'#searchResults',
        artistSectionId:			'#artistSection',
        userInputContentId: 		'#userInputCont',
        
        artistInput: 				null,
        artistInputDiv:				null,
        userInputDiv:				null,
        artistFieldset: 			null,
        userInput: 					null,
        searchResults: 				null,
        
    };

    // public
    var _public = {
    	//get ui elements. Compute them if its the first time.
        getArtistInput: 		function(){if(!_private.artistInput){_private.artistInput=$(_private.artistInputId)};return _private.artistInput;},
        getUserInput: 			function(){if(!_private.userInput){_private.userInput=$(_private.userInputId)};return _private.userInput;},
        getSearchSection:	 	function(){if(!_private.searchResults){_private.searchResults=$(_private.resultsId)};return _private.searchResults;},
        getArtistInputDiv:	 	function(){if(!_private.artistInputDiv){_private.artistInputDiv=$(_private.artistInputContentId)};return _private.artistInputDiv;},
        getUserInputDiv:	 	function(){if(!_private.userInputDiv){_private.userInputDiv=$(_private.userInputContentId)};return _private.userInputDiv;},
        getArtistFieldset:	 	function(){if(!_private.artistFieldset){_private.artistFieldset=$(_private.artistSectionId+' fieldset')};return _private.artistFieldset;},
        
        //get current values
        getArtistValue: 		function(){return this.getArtistInput().val();},
        getUserValue: 			function(){return this.getUserInput().val();},
        
        clearArtists : 			function(){
						        	//hide results section, clear artist value, reset artist validity and disable panel.
									this.displayElement(_public.getSearchSection(), false);
									if(this.getArtistInput().val()!=""){
										this.enableArtistSection(false);
										this.setFormError(this.getArtistInputDiv());
									}
									this.getArtistInput().val("");
									
						        },
		
        //change css of bootstrap form container to display success state 
        setFormSuccess : 		function(divContainer)
        						{
						        	divContainer.removeClass( "has-error" ).addClass("has-success has-feedback");
						        	divContainer.find( ".glyphicon" ).removeClass( "glyphicon-remove" ).addClass("glyphicon-ok");
					      		},
        //change css of bootstrap form container to display error state
        setFormError : 			function setCssError(divContainer)
						        {
						        	divContainer.removeClass( "has-success" ).addClass("has-error has-feedback");
						        	divContainer.find( ".glyphicon" ).removeClass( "glyphicon-ok" ).addClass("glyphicon-remove");
						        },
	   //enable the artist section (set success/error for user field and make artist section disabled or not)
       enableArtistSection : 	function(enable)
       							{
									if(enable){
										_public.setFormSuccess(_public.getUserInputDiv());
										_public.getArtistFieldset().removeAttr('disabled');
									}
									else{
										_public.getArtistFieldset().attr('disabled','');
										_public.setFormError(_public.getUserInputDiv());
									}
						       },
       //set enable state for search button						       
       enableSearchButton : 	function(isEnabled)
       							{
						    		if(isEnabled){
						    			$('#searchButton').removeClass( "disabled" );
						    		}
						    		else{
						    			$('#searchButton').addClass( "disabled" );
						    		}
    							},
       //clear result table
	   clearResults : 			function()
								{
									$('#resultsTableBody').empty();// on vide la table de ses resultats
								},
	   displayElement : 			function (element,isDisplayed)
								{
									if(isDisplayed){
										element.removeClass( "noDisplay" );
									}
									else{
										element.addClass( "noDisplay" );
									}
								},
		//display a waiting icon and hide result section.
		waitForResults : 			function()
									{
										_public.displayElement($('#resultsTable'), false);
										_public.displayElement($('#noResultsMessage'), false);
										_public.displayElement($('#searchResults'), true);
										_public.displayElement($('#waitingResults'), true);
									},
	    //display the results and hide waiting icon								
		displayResults: 			function()
									{
										_public.displayElement($('#waitingResults'), false);
										_public.displayElement($('#resultsTable'), true);
									},
	    noResults:		 			function()
									{
										_public.displayElement($('#waitingResults'), false);
										_public.displayElement($('#noResultsMessage'), true);
									},
									
		addResultInTable : 		function(value)
									{
										$('#resultsTableBody').append(
											'<tr>'
											+'<td>'+value.name +'</td>'
											
											+'<td><img src="'+ value.image[0]["#text"]+'" alt="'+value.album["#text"]+'"></td>'
											
											+'<td>'+value.album["#text"] +'</td>'
											+'<td>'+value.date["#text"] +'</td>'
											+'</tr>'
										);
									}

								
						        
    };

    return _public;

})();

/**
 * Object describing the controller
 */
var ctrl= (function () {

    // private
    var _private = {
    		userExistRequest : null,
    		searchTrackRequest: null,
    		artistExistRequest: null,
    		searchArtistsRequest: null,
    };

    // public
    var _public = {
    		doUserExists : function userExist(){
    			
    			//if a request was ongoing, abort it
    			if(_private.userExistRequest){
    				_private.userExistRequest.abort();
    			}
    			
    			//clear artists and result when changing user
    			view.clearArtists();
    			
    			//make user validity request and update artist section availability accordingly
    			_private.userExistRequest = libLFM.userExists(view.getUserValue(), view.enableArtistSection);
    		},
    		
    		//request if current artist typed exists and call handler (optional) using the result
			doArtistExist : function(valueHandler){
				
				//the handler is optional. Set it to empty function if not set.
				valueHandler = typeof valueHandler !== 'undefined' ? valueHandler : function(){};
			
				//if a request was ongoing, abort it
				if(_private.artistExistRequest){
					_private.artistExistRequest.abort();
				}
			
				view.clearResults();
				var artistName=view.getArtistValue();
		
				//au début de toute maj d'artiste on enléve les résultat
				view.displayElement($('#searchResults'), false);
				
				// artist validity data handler
				handleArtistValidity = function(artistValid){
					if (artistValid){
						view.setFormSuccess(view.getArtistInputDiv());
					}
					else{
						view.setFormError(view.getArtistInputDiv());
					}
					//update search button availability
					view.enableSearchButton(artistValid);
					
					//process validity with handler
					valueHandler(artistValid);
				};
				
				//ask api if artist is valid
				_private.artistExistRequest = libLFM.artistExists(artistName, handleArtistValidity);
			},
			
			//search track for provided arrist
			searchArtistTracks : function (artistName){
				
				//get current user name
				var userName = view.getUserInput().val();
				
				//set the view to the waiting result state
				view.waitForResults();
				
				//handler in case tracks are found 
				hasTrackHandler=function(tracks){
					//for each track...
					$.each(tracks, function(index, value) {
						view.addResultInTable(value);
					});
					view.displayResults();
				};
				
				//handler when no track is found
				noTrackHandler=function(){
					view.noResults();
				};
				
				//call LastFM request
				libLFM.getArtistTracks(userName,artistName, hasTrackHandler, noTrackHandler);
			},
			
			//search track from currently selected artist
			selectDefaultArtist : function(){
				_public.searchArtistTracks(view.getArtistInput().val());
			}
			
    };
    
    return _public;

})();


/*
 * Set autocomplete behaviour.
 */
view.getArtistInput().autocomplete({
	source : function(request, response){
				var artistName=view.getArtistValue();
				libLFM.searchArtistAsArray(artistName,10, response);
	},
	select: function (event, ui) {
		//update artist existence (sometimes suggested artists do not even exists...)
		view.getArtistInput().val(ui.item.value);
		console.log("V2");//TODEL
		ctrl.doArtistExist(
				//when artist existence is computed, if ok, start looking for its tracks.
				function(isArtistExists){
					if(isArtistExists){
						ctrl.searchArtistTracks(ui.item.value);
					}
				}
		); 
	}
})
//custom rendering of autocompletion
.autocomplete( "instance" )._renderItem = function( ul, item ) {
	return $( "<li>" )
		.append('<img src="'+ item.image+'">')
		.append(item.name)
		.appendTo( ul );
};

/*
 * Add keypress listener on artist input to launch search when enter is pressed
 */
view.getArtistInput().keypress(function (e) {
 var key = e.which;
 if(key == 13)  // the enter key code
  {
	//close autocomplete 
	view.getArtistInput().autocomplete("close");
	//validate that artist exists, and if it exists, look for it
	ctrl.doArtistExist(function(isExisting){
		if(isExisting){
			ctrl.selectDefaultArtist();
		}
	});
  }
});  			


/* FUNCTION FOR DEBUG */
//function getAllProperties(obj) {
//  var properties = '';
//  for (property in obj) {
//	properties += '\n' + property + "-" +obj[property];
//  }
//  alert('Properties of object:' + properties);
//} 


