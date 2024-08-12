module BrazilianCardinality
  module Number
    NumberTooBigError = Class.new(StandardError)

    ONES = {
      0 => 'zero',
      1 => 'um',
      2 => 'dois',
      3 => 'três',
      4 => 'quatro',
      5 => 'cinco',
      6 => 'seis',
      7 => 'sete',
      8 => 'oito',
      9 => 'nove'
    }.freeze

    TENS = {
      10 => 'dez',
      11 => 'onze',
      12 => 'doze',
      13 => 'treze',
      14 => 'quatorze',
      15 => 'quinze',
      16 => 'dezesseis',
      17 => 'dezessete',
      18 => 'dezoito',
      19 => 'dezenove',
      20 => 'vinte',
      30 => 'trinta',
      40 => 'quarenta',
      50 => 'cinquenta',
      60 => 'sessenta',
      70 => 'setenta',
      80 => 'oitenta',
      90 => 'noventa'
    }.freeze

    HUNDREDS = {
      100 => 'cento',
      200 => 'duzentos',
      300 => 'trezentos',
      400 => 'quatrocentos',
      500 => 'quinhentos',
      600 => 'seiscentos',
      700 => 'setecentos',
      800 => 'oitocentos',
      900 => 'novecentos'
    }.freeze

    class << self
      def number_cardinal(number)
        negative = number.negative? ? 'menos ' : ''
        n = number.to_i.abs

        expression = case n
                     when 0..999 then cardinal_for_0_up_to_999(n)
                     when 1000..999_999_999_999_999 then cardinal_for_thousands_to_trillions(n)
                     else raise NumberTooBigError, "#{n} is too big"
                     end

        "#{negative}#{expression}"
      end

      private

      def cardinal_for_0_up_to_999(number)
        case number
        when 0..9 then ONES[number]
        when 10..19 then TENS[number]
        when 20..99 then cardinal_for_tens_and_hundreds(number, 10)
        when 100 then 'cem'
        when 101..999 then cardinal_for_tens_and_hundreds(number, 100)
        end
      end

      def cardinal_for_thousands_to_trillions(number)
        case number
        when 1000..999_999
          cardinal_for_scale_of_thousands(number, 1_000, 'mil', 'mil')
        when 1_000_000..999_999_999
          cardinal_for_scale_of_thousands(number, 1_000_000, 'milhão', 'milhões')
        when 1_000_000_000..999_999_999_999
          cardinal_for_scale_of_thousands(number, 1_000_000_000, 'bilhão', 'bilhões')
        when 1_000_000_000_000..999_999_999_999_999
          cardinal_for_scale_of_thousands(number, 1_000_000_000_000, 'trilhão', 'trilhões')
        end
      end

      def cardinal_for_tens_and_hundreds(number, scale)
        remainder = number % scale
        words_map = scale == 10 ? TENS : HUNDREDS
        return words_map[number] if remainder.zero?
        "#{words_map[number - remainder]} e #{number_cardinal(remainder)}"
      end

      # consideramos como "nibble", aqui, uma sequência de 3 dígitos decimais, representando um múltiplo de 1, 10 e 100 na escala em que o nibble estiver
      # e.g.: 345 000 765 tem '345', '000' e '765' como nibble.
      def do_i_have_e_on_my_left (number, scale)

        # caso especial -------------------------------------------------
        # se a escala for 1 (unidades, dezenas e centenas, três dígitos mais à direita)
        if scale == 1
          # se tem centena, há duas possibilidades
          if number / 100 > 0
            # centena cheia tem 'e' à esquerda (2500, 7600, 48900, ...)
            return true if number % 100 == 0
            # centena não cheia, nao tem 'e' à esquerda (2540, 7608, 48999, ...)
            return false
          end
          # se não tem centena, vai 'e' à esquerda (1099, 2024, 56001, ...)
          return true
        end

        # caso genérico --------------------------------------------------
        # se numero for múltiplo da escala do nibble mais à esquerda (nibbles à direita só têm zeros)
        if number % scale == 0
          # fazer essa parte por processamento de texto provavelmente é a forma mais clara
          nibble = number / scale
          # se o número de dígitos diferentes de zero no nibble for exatamente 1, vai 'e' à esquerda (2500450, 3040000, ...)
          return true if nibble.to_s.count '^0' == 1
          # número de dígitos diferentes de zero dentro do nibble é dois ou três. nesse caso, já há um "e" dentro do nibble, e não pode haver um à esquerda
          return false
        end

        # se número nao for múltiplo da grandeza do nibble (há mais dígitos diferentes de zero à esquerda)
        return false
      end

      def cardinal_for_scale_of_thousands(number, scale, singular, plural)
        # parte do nibble dessa escala
        quocient = number / scale
        
        # digitos à direita
        remainder = number % scale

        # tradução completa do nibble dessa escala (102 mil, 567 bilhões, ...) com plural/singular do nome da grandeza certo
        word = quocient > 1 ? plural : singular
        high_order_units = "#{number_cardinal(quocient)} #{word}"

        # a tradução do número acaba se não houver mais dígitos à direita
        return high_order_units if remainder.zero?

        # senão, concatena o que tem até agora com a tradução do restante do número
        # aqui é preciso decidir se concatena com "e" ou com espaço vazio
        # deve-se decrementar a ordem da escala! esse método só é chamado da escala dos milhares pra cima, então não tem perigo
        scale /=  1000
        return do_i_have_e_on_my_left(remainder, scale) ? "#{high_order_units} e #{number_cardinal(remainder)}" : "#{high_order_units} #{number_cardinal(remainder)}"
      end
    end
  end
end
