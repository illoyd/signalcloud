class ConversationPricer < Pricer
  
  def price_for(conversation)
    price_with_messages(
      conversation,
      conversation.messages.outbound.challenges.sum(:segments),
      conversation.messages.outbound.replies.sum(:segments)
    )
  end
  
  def price_with_messages( conversation, challenge_count, reply_count )
    country = PhoneTools.country( conversation.customer_number )
    pricesheet = self.price_sheet_for( country )
    
    # Calculate costs for outbound messages
    question_price = [challenge_count - 1, 0].max * pricesheet.base_conversation_price / 2
    reply_price    = [reply_count - 1, 0].max * pricesheet.base_conversation_price / 2
    pricesheet.base_conversation_price + question_price + reply_price
  end

end