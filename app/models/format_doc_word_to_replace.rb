class FormatDocWordToReplace < ActiveRecord::Base
	
	XML_TAG = /\<[^\>]+\>/

	def self.word_xml_gsub! word_xml, pattern, replacement
		regexp = //
	    tag_pattern = '' # tag_pattern is the resulting replacement with the XML tags intact
	    replacement = replacement.to_s.encode(xml: :text)
	    
	    # Generate tag_pattern and regexp
	    pattern.to_s.each_char.each_with_index do |char, i|
	    	rc = Regexp.quote(char)
	    	regexp = /#{regexp}(?<tag#{i}>(#{XML_TAG})*)#{rc}/
	    	tag_pattern << '\k<tag' + i.to_s + '>'
	    	tag_pattern << replacement if i == 0
	    end

	    tag_pattern.force_encoding("ASCII-8BIT")

	    word_xml.gsub!(regexp, tag_pattern)
	end
	
end
