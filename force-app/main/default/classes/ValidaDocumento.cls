public class ValidaDocumento {//classe que valida o cpf ou o cnpj
    
    public static boolean isValidCPF(String cpf) {
        cpf = cpf.replace('.', '').replace('-', '');
        //verifica se existem caracteres não numéricos antes da validação
        Pattern nonAlphanumeric = Pattern.compile('[^0-9]');
        Matcher matcher = nonAlphanumeric.matcher(cpf);
       
        if(!cpf.equals(matcher.replaceAll(''))) return(false);
        
        if (
            cpf.equals('00000000000') || cpf.equals('11111111111') ||
            cpf.equals('22222222222') || cpf.equals('33333333333') ||
            cpf.equals('44444444444') || cpf.equals('55555555555') ||
            cpf.equals('66666666666') || cpf.equals('77777777777') ||
            cpf.equals('88888888888') || cpf.equals('99999999999') ||
            (cpf.length() != 11)
        )
            return(false);
          
        List<String> lsDigitos = cpf.split('');
        Integer somatoria, indiceDig, resto, numeroTemp, peso, dig10, dig11;
        
        //calculo do primeiro digito verificador
        somatoria = 0;
        peso = 10;
        for (indiceDig=0; indiceDig<9; indiceDig++) {
            numeroTemp = Integer.valueOf(lsDigitos[indiceDig]); 
            somatoria = somatoria + (numeroTemp * peso);
            peso = peso - 1;
        }
          
        resto = 11 - (math.mod(somatoria,11));
        if (resto>9)
            dig10 = 0;
        else dig10 = resto;
        
        //calculo do segundo digito verificador
        somatoria = 0;
        peso = 11;
        for(indiceDig=0; indiceDig<10; indiceDig++) {
            numeroTemp = Integer.valueOf(lsDigitos[indiceDig]);
            somatoria = somatoria + (numeroTemp * peso);
            peso = peso - 1;
        }
        
        resto = 11 - (math.mod(somatoria,11));
        if (resto > 9)
            dig11 = 0;
        else dig11 = resto;
        
        // verifica se os digitos calculados equivalem aos digitos informados
        if (dig10 == Integer.valueOf(lsDigitos[9]) && dig11 == Integer.ValueOf(lsDigitos[10]))
            return true;
        else return false;
  }

    public static boolean isValidCNPJ(String cnpj) {
        cnpj = cnpj.replace('.', '').replace('/', '').replace('-', '');
        //verifica se existem caracteres não numéricos antes da validação
        Pattern nonAlphanumeric = Pattern.compile('[^0-9]');
        Matcher matcher = nonAlphanumeric.matcher(cnpj);
        if(!cnpj.equals(matcher.replaceAll(''))) return(false);
        
        if (
            cnpj.equals('00000000000000') || cnpj.equals('11111111111111') ||
            cnpj.equals('22222222222222') || cnpj.equals('33333333333333') ||
            cnpj.equals('44444444444444') || cnpj.equals('55555555555555') ||
            cnpj.equals('66666666666666') || cnpj.equals('77777777777777') ||
            cnpj.equals('88888888888888') || cnpj.equals('99999999999999') ||
            (cnpj.length() != 14)
        )
            return false;
        
        Integer somatoria, indiceDig, resto, numeroTemp, peso, dig13, dig14;
        List<String> lsDigitos = cnpj.split('');
        
        //calculo do primeiro digito verificador
        somatoria = 0;
        peso = 2;
        for (indiceDig=11; indiceDig>=0; indiceDig--) {
            numeroTemp = Integer.valueOf(lsDigitos[indiceDig]);
            somatoria = somatoria + (numeroTemp * peso);
            peso = peso + 1;
            if (peso == 10)
                peso = 2;
        }
        
        resto = math.mod(somatoria, 11);
        if ((resto == 0) || (resto == 1))
            dig13 = 0;
        else dig13 = Integer.valueOf(11-resto);
        
        //calculo do segundo digito verificador
        somatoria = 0;
        peso = 2;
        for (indiceDig=12; indiceDig>=0; indiceDig--) {
            numeroTemp = Integer.valueOf(lsDigitos[indiceDig]);
            somatoria = somatoria + (numeroTemp * peso);
            peso = peso + 1;
            if (peso == 10)
                peso = 2;
        }
        
        resto = math.mod(somatoria, 11);
        if ((resto == 0) || (resto == 1))
            dig14 = 0;
        else dig14 = Integer.valueOf(11-resto);
        
        // verifica se os digitos calculados equivalem aos digitos informados
        if (dig13 == Integer.valueOf(lsDigitos[12]) && dig14 == Integer.valueOf(lsDigitos[13]))
            return true;
        else return false ;
    }

	public static String formatarCPF (String numeroCPF) {
        numeroCPF = String.isBlank(numeroCPF) ? '' : numeroCPF.replaceAll('\\D', '');
        if (numeroCPF.length() != 11) {
            return numeroCPF;
        }
        String cpfFormatado = numeroCPF.substring(0, 3) + '.' + numeroCPF.substring(3, 6) + '.' +
            numeroCPF.substring(6, 9) + '-' + numeroCPF.substring(9);
        return cpfFormatado;
    }
    
    public static String formatarCNPJ (String numeroCNPJ) {
        numeroCNPJ = String.isBlank(numeroCNPJ) ? '' : numeroCNPJ.replaceAll('\\D', '');
        if (numeroCNPJ.length() != 14) {
            return numeroCNPJ;
        }
        String cnpjFormatado = numeroCNPJ.substring(0, 2) + '.' + numeroCNPJ.substring(2, 5) + '.' +
            numeroCNPJ.substring(5, 8) + '/' + numeroCNPJ.substring(8, 12) + '-' + numeroCNPJ.substring(12);
        return cnpjFormatado; 
    }
}