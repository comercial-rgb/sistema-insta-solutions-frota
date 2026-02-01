class RoomChannel < ApplicationCable::Channel
	
	def subscribed
		if !params[:first_id].nil? && !params[:last_id].nil?
			stream_from "room_channel##{params[:first_id]}##{params[:last_id]}"
		end
	end

	def unsubscribed
	end

	def speak(data)
		message = Message.create(
			content: data['message'], 
			sender_id: data['sender_id'], 
			receiver_id: data['receiver_id']
			)
		ActionCable.server.broadcast("room_channel##{data['first_id']}##{data['last_id']}", {message: message.reload})
	end
end
