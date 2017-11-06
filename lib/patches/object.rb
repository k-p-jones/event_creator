# need to add this to get thr gmail gem to work. 
# Im aware how awful this is. 
class Object
  def to_imap_date
    date = respond_to?(:utc) ? utc.to_s : to_s
    Date.parse(date).strftime("%d-%b-%Y")
  end
end
