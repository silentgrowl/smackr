java_import 'org.jivesoftware.smackx.muc.MultiUserChat'
java_import 'org.jivesoftware.smackx.muc.DiscussionHistory'
java_import 'org.jivesoftware.smack.SmackConfiguration'
java_import 'org.jivesoftware.smack.packet.Message'

class Smackr
  class Room
    attr_reader :room
    attr_accessor :message_callback, :participant_callback, :joined_callback, :left_callback
    attr_accessor :messages

    def initialize(opts={})
      [:connection, :roomname, :nickname].each do |field|
        unless opts[field]
          raise ArgumentError, "#{field} is required"
        end
      end

      self.messages = []

      history = DiscussionHistory.new;
      unless opts[:history].nil?
        history.set_max_stanzas(opts[:history]);
      end

      @message_callback = opts[:message_callback]
      puts "@message_callback = #{@message_callback}"

      @room = MultiUserChat.new(opts[:connection], opts[:roomname]);
      @room.join(opts[:nickname], opts[:password], history, SmackConfiguration.get_packet_reply_timeout());
      @room.add_message_listener(PacketReceiver.new(:room => self))
      @room.add_participant_listener(ParticipantReceiver.new(:room => self))
      @room.add_participant_status_listener(ParticipantStatusReceiver.new(:room => self))
    end

    def send_message(msg)
      if msg.is_a?(String)
        self.room.send_message(msg)
      else #TODO Make this actually work with non-string messages
        raise Exception, "YELL AT BOB TO MAKE THIS WORK!"
      end
    end

    class PacketReceiver
      include org.jivesoftware.smack.PacketListener
      attr_accessor :room

      def initialize(opts={})
        self.room = opts[:room]
      end

      def process_packet(packet)
        room.messages << packet
        room.message_callback.call(packet, room.room) if room.message_callback
      end
    end

    class ParticipantReceiver
      include org.jivesoftware.smack.PacketListener
      attr_accessor :room

      def initialize(opts={})
        self.room = opts[:room]
      end

      def process_packet(packet)
        room.messages << packet
        room.participant_callback.call(packet, room.room) if room.participant_callback
      end
    end

    class ParticipantStatusReceiver
      include org.jivesoftware.smackx.muc.ParticipantStatusListener
      attr_accessor :room

      def initialize(opts={})
        self.room = opts[:room]
      end

      def joined(participant)
        room.joined_callback.call(participant, room.room) if room.joined_callback
      end

      def left(participant)
        room.left_callback.call(participant, room.room) if room.left_callback
      end
    end
  end
end
