IF EXISTS(SELECT * FROM sysobjects WHERE name='SaveJuchuDataEcRenkei_Ex')
   DROP PROCEDURE dbo.SaveJuchuDataEcRenkei_Ex
GO

CREATE PROCEDURE SaveJuchuDataEcRenkei_Ex
@KAISHA_CD  NVARCHAR(15),                                            --��ЃR�[�h
@USER_ID    NVARCHAR(30),                                            --���[�UID
@FILE_PATH  NVARCHAR(200)                                            --�t�@�C���p�X
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ERR_MSG_MANDATORY_FIELD			NVARCHAR(20)	= '�K�{���ږ��ݒ�'
	DECLARE @ERR_MSG_INCORRECT_DATA				NVARCHAR(20)	= '���͒l�s��'
	DECLARE @ERR_MSG_INVALID_NUMBER				NVARCHAR(20)	= '���l�͈͕s��'
	DECLARE @ERR_MSG_INCORRECT_CODE				NVARCHAR(20)	= '�R�[�h�s��'
	DECLARE @ERR_MSG_CANNOT_USE_CODE			NVARCHAR(20)	= '�w��s�R�[�h'
	DECLARE @ERR_MSG_NOT_EXIST_HINMOKU			NVARCHAR(20)	= '�Y���i�ڃR�[�h��'
	DECLARE @ERR_MSG_CANNOT_USE_HINMOKU			NVARCHAR(20)	= '�o�ג�~�i��'
	DECLARE @ERR_MSG_CANNOT_USE_YOYAKU			NVARCHAR(20)	= '�w��s�\��`�['
	DECLARE @ERR_MSG_JUCHU_ZAM_KANRI_DATE		NVARCHAR(20)	= '���c�Ȃ��F���t�ݒ�s��'
	DECLARE @ERR_MSG_JUCHU_ZAM_KANRI_SHUKKASAKI	NVARCHAR(20)	= '���c�Ȃ��F�o�א�s��'
	DECLARE @ERR_MSG_SEIKYUKIJUN_DATE			NVARCHAR(20)	= '��������s��'
	DECLARE @ERR_MSG_CANNOT_ZAIKOKNARI			NVARCHAR(30)	= '�a���E�a��E�\��E�q�Ɉړ��s���F�݌ɊǗ��Ȃ��i��'
	DECLARE @ERR_MSG_AZUKE_AZUKARI_SOKO			NVARCHAR(20)	= '�a����E�a���F�q�ɋ敪�s��'
	DECLARE @ERR_MSG_TUJOU_SHUKKO_SOKO			NVARCHAR(20)	= '�ʏ�o�ɁF�q�ɋ敪�s��'
	DECLARE @ERR_MSG_SOKO_IDO_SHUKKO_KBN		NVARCHAR(20)	= '�q�Ɉړ��F�q�ɋ敪�s��'
	DECLARE @ERR_MSG_DTL_COUNT_OVER				NVARCHAR(20)	= '�󒍓`�[�̖��׌���(999��)�I�[�o�['
	DECLARE @ERR_MSG_DIFFERENT_TUKA				NVARCHAR(20)	= '�قȂ����ʉ�'
	DECLARE @ERR_MSG_YOSHIN_GENDO				NVARCHAR(20)	= '�^�M���x�z�I�[�o�['
	DECLARE @ERR_MSG_SOKO_IDO_SOKO				NVARCHAR(20)	= '�ړ����E�ړ���q�ɂ�����'
	DECLARE @ERR_MSG_SOKO_TENPO					NVARCHAR(20)	= '�ړ����A�ړ��悪�����X��'

	DECLARE @ALERT_MSG_HOLIDAY					NVARCHAR(20)	= '�x���F�o�ח\���'
	DECLARE @ALERT_MSG_SEIKYU					NVARCHAR(20)	= '��������'

	DECLARE @FLD_JUCHU_KBN_YOYAKU				NVARCHAR(20)	= '�y�\��`�[�z'
	DECLARE @FLD_JUCHU_KBN_SOKO_IDO				NVARCHAR(20)	= '�y�q�Ɉړ��z'

	DECLARE @FLD_NM_JUCHU_KBN					NVARCHAR(28)	= '(�󒍋敪)'+ NCHAR(13) +'�󒍋敪'
	DECLARE @FLD_NM_JUCHU_DATE					NVARCHAR(28)	= '(�󒍓�)'+ NCHAR(13) +'�󒍓�'
	DECLARE @FLD_NM_SHUKKO_KBN					NVARCHAR(28)	= '(�o�ɋ敪)'+ NCHAR(13) +'�o�ɋ敪'
	DECLARE @FLD_NM_TOKUISAKI_CD				NVARCHAR(28)	= '(���Ӑ�R�[�h)'+ NCHAR(13) +'���Ӑ�R�[�h'
	DECLARE @FLD_NM_SHUKKASAKI_CD				NVARCHAR(28)	= '(�o�א�R�[�h)'+ NCHAR(13) +'�w�b�_�o�א�R�[�h'
	DECLARE @FLD_NM_SEIKYUSAKI_CD				NVARCHAR(28)	= '(������R�[�h)'+ NCHAR(13) +'������R�[�h'
	DECLARE @FLD_NM_SOKO_CD						NVARCHAR(28)	= '(�q�ɃR�[�h)'+ NCHAR(13) +'�w�b�_�q�ɃR�[�h'
	DECLARE @FLD_NM_AZUKE_AZUKARI_IDO_SOKO_CD	NVARCHAR(28)	= '(�a���^�a����^�ړ��q�ɃR�[�h)'+ NCHAR(13) +'�a���a����ړ��q�ɃR�[�h'
	DECLARE @FLD_NM_HDR_SHUKKA_YOTEI_DATE		NVARCHAR(28)	= '(�w�b�_�o�ח\���)'+ NCHAR(13) +'�w�b�_�o�ח\���'
	DECLARE @FLD_NM_DTL_SHUKKA_YOTEI_DATE		NVARCHAR(28)	= '(���׏o�ח\���)'+ NCHAR(13) +'���׏o�ח\���'
	DECLARE @FLD_NM_SHITEI_NOHIN_DATE			NVARCHAR(28)	= '(�w�b�_�w��[�i��)'+ NCHAR(13) +'�w�b�_�w��[�i��'
	DECLARE @FLD_NM_SHITEI_NOHIN_JIKOKU			NVARCHAR(28)	= '(�w��[�i����)'+ NCHAR(13) +'�w��[�i����'
	DECLARE @FLD_NM_HAISOU_KBN					NVARCHAR(28)	= '(�z���敪)'+ NCHAR(13) +'�z���敪'
	DECLARE @FLD_NM_KESSAI_HOHO					NVARCHAR(28)	= '(���ϕ��@)'+ NCHAR(13) +'���ϕ��@'
	DECLARE @FLD_NM_HDR_GEDAIMACHI_FLG			NVARCHAR(28)	= '(����҂��t���O)'+ NCHAR(13) +'����҂��t���O'
	DECLARE @FLD_NM_SAMPLE_SHUKKA_FLG			NVARCHAR(28)	= '(�T���v���o�׃t���O)'+ NCHAR(13) +'�T���v���o�׃t���O'
	DECLARE @FLD_NM_HIKIATE_CHOSEI_FUYO_FLG		NVARCHAR(28)	= '(���������s�p�t���O)'+ NCHAR(13) +'���������s�p�t���O'
	DECLARE @FLD_NM_SEIKYU_KIJUN_DATE			NVARCHAR(28)	= '(�������)'+ NCHAR(13) +'�w�b�_�������'
	DECLARE @FLD_NM_TOKUISAKI_DENPYO_NO			NVARCHAR(28)	= '(���Ӑ�`�[NO)'+ NCHAR(13) +'���Ӑ�`�[NO'
	DECLARE @FLD_NM_TOKUISAKI_HACCHU_NO			NVARCHAR(28)	= '(���Ӑ攭��NO)'+ NCHAR(13) +'���Ӑ攭��NO'
	DECLARE @FLD_NM_BUNRUI_CD					NVARCHAR(28)	= '(���ރR�[�h)'+ NCHAR(13) +'���ރR�[�h'
	DECLARE @FLD_NM_URIBA_NM					NVARCHAR(28)	= '(���ꖼ)'+ NCHAR(13) +'���ꖼ'
	DECLARE @FLD_NM_TANTOSHA_NM					NVARCHAR(28)	= '(�S���Җ�)'+ NCHAR(13) +'�S���Җ�'
	DECLARE @FLD_NM_NAISEN_NO					NVARCHAR(28)	= '(�����ԍ�)'+ NCHAR(13) +'�����ԍ�'
	DECLARE @FLD_NM_TANTOSHA_CD					NVARCHAR(28)	= '(�S���҃R�[�h)'+ NCHAR(13) +'�S���҃R�[�h'
	DECLARE @FLD_NM_TANTO_BUSHO_CD				NVARCHAR(28)	= '(�S�������R�[�h)'+ NCHAR(13) +'�S�������R�[�h'
	DECLARE @FLD_NM_NOHIN_KBN					NVARCHAR(28)	= '(�[�i�敪)'+ NCHAR(13) +'�[�i�敪'
	DECLARE @FLD_NM_RYUTU_KAKOU_KBN				NVARCHAR(28)	= '(���ʉ��H�敪)'+ NCHAR(13) +'���ʉ��H�敪'
	DECLARE @FLD_NM_BIKO						NVARCHAR(28)	= '(�w�b�_���l)'+ NCHAR(13) +'�w�b�_���l'
	DECLARE @FLD_NM_JUCHU_COMMENT				NVARCHAR(28)	= '(�󒍃R�����g)'+ NCHAR(13) +'�󒍃R�����g'
	DECLARE @FLD_NM_SOKO_COMMENT				NVARCHAR(28)	= '(�q�ɃR�����g)'+ NCHAR(13) +'�q�ɃR�����g'
	DECLARE @FLD_NM_PROJECT_CD					NVARCHAR(28)	= '(�v���W�F�N�g�R�[�h)'+ NCHAR(13) +'�v���W�F�N�g�R�[�h'
	DECLARE @FLD_NM_HANBAI_AREA_CD				NVARCHAR(28)	= '(�̔��G���A�R�[�h)'+ NCHAR(13) +'�̔��G���A�R�[�h'
	DECLARE @FLD_NM_YOYAKU_KAIHO_KIGEN			NVARCHAR(28)	= '(�\��������)'+ NCHAR(13) +'�\��������'
	DECLARE @FLD_NM_HINMOKU						NVARCHAR(28)	= '(�i��)'+ NCHAR(13) +'�i��'
	DECLARE @FLD_NM_LOT_NUM						NVARCHAR(28)	= '(���b�g��)'+ NCHAR(13) +'���b�g��'
	DECLARE @FLD_NM_BARA_NUM					NVARCHAR(28)	= '(�o����)'+ NCHAR(13) +'�o����'
	DECLARE @FLD_NM_SUITEI_KAKUTEI_KBN			NVARCHAR(28)	= '(����m��敪)'+ NCHAR(13) +'����m��敪'
	DECLARE @FLD_NM_KAKERITU					NVARCHAR(28)	= '(�|��)'+ NCHAR(13) +'�|��'
	DECLARE @FLD_NM_JUCYU_TANKA					NVARCHAR(28)	= '(�󒍒P��)'
	DECLARE @FLD_NM_HIKIATE_STATE				NVARCHAR(28)	= '(�������)'+ NCHAR(13) +'�������'
	DECLARE @FLD_NM_DTL_GEDAIMACHI_FLG			NVARCHAR(28)	= '(����҂��t���O)'+ NCHAR(13) +'���׉���҂��t���O'
	DECLARE @FLD_NM_TEKIYO						NVARCHAR(28)	= '(�E�v)'+ NCHAR(13) +'�E�v'
	DECLARE @FLD_NM_YOYAKU_DENPYO_NO			NVARCHAR(28)	= '(�\��`�[NO)'+ NCHAR(13) +'�\��`�[NO'
	DECLARE @FLD_NM_YOYAKU_DENPYO_ENO			NVARCHAR(28)	= '(�\��`�[�}��)'+ NCHAR(13) +'�\��`�[�}��'
	DECLARE @FLD_NM_KAZEI_KBN					NVARCHAR(28)	= '(�ېŋ敪)'+ NCHAR(13) +'�ېŋ敪'
	DECLARE @FLD_NM_TORIHIKISAKI_TUKA_TANKA		NVARCHAR(28)	= '(�����ʉݒP��)'+ NCHAR(13) +'�����ʉݒP��'
	DECLARE @FLD_NM_RATE						NVARCHAR(28)	= '(���[�g)'+ NCHAR(13) +'���[�g'
	DECLARE @FLD_NM_DTL_BIKO					NVARCHAR(28)	= '(���ה��l)'+ NCHAR(13) +'���ה��l'

	--INT�ϐ����^�[���R�[�h(@RetCd)�������l0�Œ�`
	DECLARE @RetCd int = 0

	--�P�������A���ʌ����̒�`�l���擾
	DECLARE @TANKA_KETA NVARCHAR(10) 
			,@SURYO_KETA NVARCHAR(10)
			,@PGM_CD NVARCHAR(50)

	--�P������
	SELECT @TANKA_KETA = VALUE FROM BC_MST_SYSTEM
	WHERE KAISHA_CD = @KAISHA_CD
	AND BUNRUI_NM = 'CO'
	AND VALUE_NM = 'TANKA_KETA'

	--���ʌ���
    SELECT @SURYO_KETA = VALUE FROM BC_MST_SYSTEM
    WHERE KAISHA_CD = @KAISHA_CD
    AND BUNRUI_NM = 'CO'
    AND VALUE_NM = 'SURYO_KETA'

	--B2B�o�^�v���O�����R�[�h
    SELECT @PGM_CD = VALUE FROM BC_MST_SYSTEM
    WHERE KAISHA_CD = @KAISHA_CD
    AND BUNRUI_NM = 'HK'
    AND VALUE_NM = 'B2B_INS_PGM_CD' 

	--��Ѓ}�X�^�̒ʉ݃R�[�h�擾
	--���{�~��ʉ݃R�[�h�ɐݒ肷��Ƃ̂���
	DECLARE @TUKA_CD NVARCHAR(15) 
	SELECT @TUKA_CD = TUKA_CD
	FROM BC_MST_KAISHA_GAIKA
	WHERE KAISHA_CD = @KAISHA_CD

	--�捞�󒍃f�[�^�p�ꎞ�e�[�u��
	CREATE TABLE #tmp
    (
		LINE_NO						DECIMAL(6) PRIMARY KEY	--(�t�����)�t�@�C���s�ԍ�
	   ,ERROR_MSG					NVARCHAR(100)			--(�t�����)�G���[���e
	   ,TMP_ID						DECIMAL(6)				--(�t�����)�ꎞID
	   ,GROUP_KEY					DECIMAL(6)				--(�t�����)�O���[�v�L�[
	   ,DENPYO_NO					NVARCHAR(12)			--(�t�����)�`�[NO
	   ,DENPYO_ENO					DECIMAL(3)				--(�t�����)�`�[�}��
	   ,HINMOKU_SEQ					DECIMAL(10)				--(�t�����)�i��SEQ
	   ,SURYO						DECIMAL(13, 3)			--(�t�����)�󒍐���
	   ,JUCHU_TANKA					DECIMAL(14, 4)			--(�t�����)�󒍒P��
	   ,TAX_RATE					DECIMAL(3, 2)			--(�t�����)�ŗ�
	   ,TAX_SITEI_KBN				NVARCHAR(5)				--(�t�����)�ŗ��w�E�敪
	   ,KAKERITU_REF_KBN			NVARCHAR(5)				--(�t�����)�|���Q�Ƌ敪
	   ,HIKIATE_KBN					NVARCHAR(5)				--(�t�����)�����敪(���ׂ̊g��TBL)
	   ,JUCHU_KBN					NVARCHAR(MAX)			--�󒍋敪
	   ,JUCHU_DATE					NVARCHAR(MAX)			--�󒍓�
	   ,SHUKKO_KBN					NVARCHAR(MAX)			--�o�ɋ敪
	   ,TOKUISAKI_CD				NVARCHAR(MAX)			--���Ӑ�R�[�h
	   ,SHUKKASAKI_CD				NVARCHAR(MAX)			--�o�א�R�[�h
	   ,SEIKYUSAKI_CD				NVARCHAR(MAX)			--������R�[�h
	   ,SOKO_CD						NVARCHAR(MAX)			--�q�ɃR�[�h
	   ,AZUKE_AZUKARI_IDO_SOKO_CD	NVARCHAR(MAX)			--�a���^�a����^�ړ��q�ɃR�[�h
	   ,SHUKKA_YOTEI_DATE			NVARCHAR(MAX)			--�o�ח\���
	   ,SHITEI_NOHIN_DATE			NVARCHAR(MAX)			--�w��[�i��
	   ,SHITEI_NOHIN_JIKOKU			NVARCHAR(MAX)			--�w��[�i����
	   ,HAISOU_KBN					NVARCHAR(MAX)			--�z���敪
	   ,KESSAI_HOHO					NVARCHAR(MAX)			--���ϕ��@
	   ,HDR_GEDAIMACHI_FLG			NVARCHAR(MAX)			--����҂��t���O
	   ,SAMPLE_SHUKKA_FLG			NVARCHAR(MAX)			--�T���v���o�׃t���O
	   ,HIKIATE_CHOSEI_FUYO_FLG		NVARCHAR(MAX)			--���������s�p�t���O
	   ,HDR_SEIKYU_KIJUN_DATE		NVARCHAR(MAX)			--�������
	   ,TOKUISAKI_DENPYO_NO			NVARCHAR(MAX)			--���Ӑ�`�[NO
	   ,TOKUISAKI_HACCHU_NO			NVARCHAR(MAX)			--���Ӑ攭��NO
	   ,BUNRUI_CD					NVARCHAR(MAX)			--���ރR�[�h
	   ,URIBA_NM					NVARCHAR(MAX)			--���ꖼ
	   ,TANTOSHA_NM					NVARCHAR(MAX)			--�S���Җ�
	   ,NAISEN_NO					NVARCHAR(MAX)			--�����ԍ�
	   ,TANTOSHA_CD					NVARCHAR(MAX)			--�S���҃R�[�h
	   ,TANTO_BUSHO_CD				NVARCHAR(MAX)			--�S�������R�[�h
	   ,NOHIN_KBN					NVARCHAR(MAX)			--�[�i�敪
	   ,RYUTU_KAKOU_KBN				NVARCHAR(MAX)			--���ʉ��H�敪
	   ,BIKO						NVARCHAR(MAX)			--���l
	   ,JUCHU_COMMENT				NVARCHAR(MAX)			--�󒍃R�����g
	   ,SOKO_COMMENT				NVARCHAR(MAX)			--�q�ɃR�����g
	   ,PROJECT_CD					NVARCHAR(MAX)			--�v���W�F�N�g�R�[�h
	   ,HANBAI_AREA_CD				NVARCHAR(MAX)			--�̔��G���A�R�[�h
	   ,YOYAKU_KAIHO_KIGEN			NVARCHAR(MAX)			--�\��������
	   ,HINMOKU						NVARCHAR(MAX)			--�i��
	   ,LOT_NUM						NVARCHAR(MAX)			--���b�g��
	   ,BARA_NUM					NVARCHAR(MAX)			--�o����
	   ,SUITEI_KAKUTEI_KBN			NVARCHAR(MAX)			--����m��敪
	   ,KAKERITU					NVARCHAR(MAX)			--�|��(%)
	   ,HIKIATE_STATE				NVARCHAR(MAX)			--�������
	   ,DTL_GEDAIMACHI_FLG			NVARCHAR(MAX)			--����҂��t���O
	   ,DTL_SOKO_CD					NVARCHAR(MAX)			--�q�ɃR�[�h
	   ,TEKIYO						NVARCHAR(MAX)			--�E�v
	   ,DTL_SHUKKASAKI_CD			NVARCHAR(MAX)			--�o�א�R�[�h
	   ,DTL_SHUKKA_YOTEI_DATE		NVARCHAR(MAX)			--�o�ח\���
	   ,DTL_SHITEI_NOHIN_DATE		NVARCHAR(MAX)			--�w��[�i��
	   ,DTL_SEIKYU_KIJUN_DATE		NVARCHAR(MAX)			--�������
	   ,YOYAKU_DENPYO_NO			NVARCHAR(MAX)			--�\��`�[NO
	   ,YOYAKU_DENPYO_ENO			NVARCHAR(MAX)			--�\��`�[�}��
	   ,KAZEI_KBN					NVARCHAR(MAX)			--�ېŋ敪
	   ,TORIHIKISAKI_TUKA_TANKA		NVARCHAR(MAX)			--�����ʉݒP��
	   ,RATE						NVARCHAR(MAX)			--���[�g
	   ,DTL_BIKO					NVARCHAR(MAX)			--���l(����)
	)

	--�w�b�_���ꎞ�e�[�u��
	CREATE TABLE #tmpHdr
    (
	    TMP_ID						DECIMAL(6)				--(�t�����)�ꎞID
	   ,GROUP_KEY					DECIMAL(6)				--(�t�����)�O���[�v�L�[
	   ,DENPYO_NO					NVARCHAR(12)			--(�t�����)�`�[NO
	   ,HACCHU_NO					NVARCHAR(12)			--(�t�����)����NO(�q�Ɉړ��p)
	   ,SOKO_IDO_NO					NVARCHAR(12)			--(�t�����)�q�Ɉړ�NO(�q�Ɉړ��p)
	   ,JUCHU_KBN					NVARCHAR(MAX)			--�󒍋敪
	   ,JUCHU_DATE					NVARCHAR(MAX)			--�󒍓�
	   ,SHUKKO_KBN					NVARCHAR(MAX)			--�o�ɋ敪
	   ,TOKUISAKI_CD				NVARCHAR(MAX)			--���Ӑ�R�[�h
	   ,SHUKKASAKI_CD				NVARCHAR(MAX)			--�o�א�R�[�h
	   ,SEIKYUSAKI_CD				NVARCHAR(MAX)			--������R�[�h
	   ,SOKO_CD						NVARCHAR(MAX)			--�q�ɃR�[�h
	   ,AZUKE_AZUKARI_IDO_SOKO_CD	NVARCHAR(MAX)			--�a���^�a����^�ړ��q�ɃR�[�h
	   ,SHUKKA_YOTEI_DATE			NVARCHAR(MAX)			--�o�ח\���
	   ,SHITEI_NOHIN_DATE			NVARCHAR(MAX)			--�w��[�i��
	   ,SHITEI_NOHIN_JIKOKU			NVARCHAR(MAX)			--�w��[�i����
	   ,HAISOU_KBN					NVARCHAR(MAX)			--�z���敪
	   ,KESSAI_HOHO					NVARCHAR(MAX)			--���ϕ��@
	   ,HDR_GEDAIMACHI_FLG			NVARCHAR(MAX)			--����҂��t���O
	   ,SAMPLE_SHUKKA_FLG			NVARCHAR(MAX)			--�T���v���o�׃t���O
	   ,HIKIATE_CHOSEI_FUYO_FLG		NVARCHAR(MAX)			--���������s�p�t���O
	   ,HDR_SEIKYU_KIJUN_DATE		NVARCHAR(MAX)			--�������
	   ,TOKUISAKI_DENPYO_NO			NVARCHAR(MAX)			--���Ӑ�`�[NO
	   ,TOKUISAKI_HACCHU_NO			NVARCHAR(MAX)			--���Ӑ攭��NO
	   ,BUNRUI_CD					NVARCHAR(MAX)			--���ރR�[�h
	   ,URIBA_NM					NVARCHAR(MAX)			--���ꖼ
	   ,TANTOSHA_NM					NVARCHAR(MAX)			--�S���Җ�
	   ,NAISEN_NO					NVARCHAR(MAX)			--�����ԍ�
	   ,TANTOSHA_CD					NVARCHAR(MAX)			--�S���҃R�[�h
	   ,TANTO_BUSHO_CD				NVARCHAR(MAX)			--�S�������R�[�h
	   ,NOHIN_KBN					NVARCHAR(MAX)			--�[�i�敪
	   ,RYUTU_KAKOU_KBN				NVARCHAR(MAX)			--���ʉ��H�敪
	   ,BIKO						NVARCHAR(MAX)			--���l
	   ,JUCHU_COMMENT				NVARCHAR(MAX)			--�󒍃R�����g
	   ,SOKO_COMMENT				NVARCHAR(MAX)			--�q�ɃR�����g
	   ,PROJECT_CD					NVARCHAR(MAX)			--�v���W�F�N�g�R�[�h
	   ,HANBAI_AREA_CD				NVARCHAR(MAX)			--�̔��G���A�R�[�h
	   ,YOYAKU_KAIHO_KIGEN			NVARCHAR(MAX)			--�\��������
	   ,HINMOKU						NVARCHAR(MAX)			--�i��
	   ,LOT_NUM						NVARCHAR(MAX)			--���b�g��
	   ,BARA_NUM					NVARCHAR(MAX)			--�o����
	   ,SUITEI_KAKUTEI_KBN			NVARCHAR(MAX)			--����m��敪
	   ,KAKERITU					NVARCHAR(MAX)			--�|��(%)
	   ,HIKIATE_STATE				NVARCHAR(MAX)			--�������
	   ,DTL_GEDAIMACHI_FLG			NVARCHAR(MAX)			--����҂��t���O
	   ,DTL_SOKO_CD					NVARCHAR(MAX)			--�q�ɃR�[�h
	   ,TEKIYO						NVARCHAR(MAX)			--�E�v
	   ,DTL_SHUKKASAKI_CD			NVARCHAR(MAX)			--�o�א�R�[�h
	   ,DTL_SHUKKA_YOTEI_DATE		NVARCHAR(MAX)			--�o�ח\���
	   ,DTL_SHITEI_NOHIN_DATE		NVARCHAR(MAX)			--�w��[�i��
	   ,DTL_SEIKYU_KIJUN_DATE		NVARCHAR(MAX)			--�������
	)

	--�ꎞ�e�[�u���Ƀf�[�^���ꊇ�}������
   BEGIN TRY    
        DECLARE @CMD NVARCHAR(1000)
        SET @CMD =
            'BULK INSERT #tmp FROM '''
            + @FILE_PATH +
            ''' WITH (
                FIELDTERMINATOR='','',
                DATAFILETYPE = ''widechar '',
                KEEPNULLS
            )'
        EXECUTE(@CMD)
   END TRY
   BEGIN CATCH
		SET @RetCd = 1;
		GOTO END_PROC
   END CATCH
 
   /*===============================���͏��̉��HSTART===============================*/
   /**********************************************
    *�i��SEQ�ݒ�START
    **********************************************/
	--�@�i�ڃ}�X�^
	UPDATE #tmp
	SET HINMOKU_SEQ = HINKAN.HINMOKU_SEQ
	FROM #tmp
	INNER JOIN BC_MST_HINMOKU HIN
		ON #tmp.HINMOKU = HIN.HINMOKU_CD
		AND HIN.MUKOU_FLG = 0
		AND HIN.DEL_FLG = 0
	INNER JOIN BC_MST_HINMOKU_KANRI HINKAN
		ON HIN.KAISHA_CD = HINKAN.KAISHA_CD
		AND HIN.HINMOKU_CD = HINKAN.HINMOKU_CD
		AND HINKAN.DEL_FLG = 0
	WHERE #tmp.ERROR_MSG IS NULL
	AND HIN.KAISHA_CD = @KAISHA_CD
	AND #tmp.HINMOKU_SEQ IS NULL

	--�A���Ӑ�ʕi�ڃ}�X�^
	UPDATE #tmp
	SET HINMOKU_SEQ = HINKAN.HINMOKU_SEQ
	FROM #tmp
	INNER JOIN BC_MST_TOKUISAKI TOKUI
		ON #tmp.TOKUISAKI_CD = TOKUI.TOKUISAKI_CD
		AND TOKUI.MUKOU_FLG = 0
		AND TOKUI.DEL_FLG = 0
	LEFT JOIN BC_MST_TOKUISAKIBETU_HINMOKU TOKUI_HIN
		ON TOKUI.KAISHA_CD = TOKUI_HIN.KAISHA_CD
		AND TOKUI.TOKUISAKI_CD = TOKUI_HIN.TOKUISAKI_CD
		AND #tmp.HINMOKU = TOKUI_HIN.TOKUISAKI_SHOHIN_CD
		AND TOKUI_HIN.DEL_FLG = 0
	LEFT JOIN BC_MST_TOKUISAKIBETU_HINMOKU_EX TOKUI_HIN_EX
		ON TOKUI.KAISHA_CD = TOKUI_HIN_EX.KAISHA_CD
		AND TOKUI.TOKUISAKI_CD = TOKUI_HIN_EX.TOKUISAKI_CD
		AND #tmp.HINMOKU = TOKUI_HIN_EX.TOKUISAKI_SHOHIN_CD2
	INNER JOIN BC_MST_HINMOKU_KANRI HINKAN
		ON HINKAN.KAISHA_CD = @KAISHA_CD
		AND HINKAN.HINMOKU_SEQ = 
				CASE WHEN TOKUI_HIN.HINMOKU_SEQ IS NOT NULL
						THEN TOKUI_HIN.HINMOKU_SEQ
					 ELSE TOKUI_HIN_EX.HINMOKU_SEQ
				END
		AND HINKAN.DEL_FLG = 0
	INNER JOIN BC_MST_HINMOKU HIN
		ON HINKAN.KAISHA_CD = HIN.KAISHA_CD
		AND HINKAN.HINMOKU_CD = HIN.HINMOKU_CD
		AND HIN.MUKOU_FLG = 0
		AND HIN.DEL_FLG = 0
	WHERE #tmp.ERROR_MSG IS NULL
	AND TOKUI.KAISHA_CD = @KAISHA_CD
	AND TOKUI.TOKUISAKI_CD IS NOT NULL
	AND #tmp.HINMOKU_SEQ IS NULL

	--�B���Ӑ�ʕi�ڃ}�X�^�i�e���Ӑ�j
	UPDATE #tmp
	SET HINMOKU_SEQ = HINKAN.HINMOKU_SEQ
	FROM #tmp
	INNER JOIN BC_MST_TOKUISAKI TOKUI
		ON #tmp.TOKUISAKI_CD = TOKUI.TOKUISAKI_CD
		AND TOKUI.MUKOU_FLG = 0
		AND TOKUI.DEL_FLG = 0
	INNER JOIN BC_MST_TOKUISAKI_EX TOKUI_EX
		ON TOKUI.KAISHA_CD = TOKUI_EX.KAISHA_CD
		AND TOKUI.TOKUISAKI_CD = TOKUI_EX.TOKUISAKI_CD
	INNER JOIN BC_MST_TOKUISAKI OYA_TOKUI
		ON OYA_TOKUI.KAISHA_CD = TOKUI_EX.KAISHA_CD
		AND OYA_TOKUI.TOKUISAKI_CD = TOKUI_EX.OYA_TOKUISAKI_CD
		AND OYA_TOKUI.MUKOU_FLG = 0
		AND OYA_TOKUI.DEL_FLG = 0
	LEFT JOIN BC_MST_TOKUISAKIBETU_HINMOKU TOKUI_HIN
		ON OYA_TOKUI.KAISHA_CD = TOKUI_HIN.KAISHA_CD
		AND OYA_TOKUI.TOKUISAKI_CD = TOKUI_HIN.TOKUISAKI_CD
		AND #tmp.HINMOKU = TOKUI_HIN.TOKUISAKI_SHOHIN_CD
		AND TOKUI_HIN.DEL_FLG = 0
	LEFT JOIN BC_MST_TOKUISAKIBETU_HINMOKU_EX TOKUI_HIN_EX
		ON OYA_TOKUI.KAISHA_CD = TOKUI_HIN_EX.KAISHA_CD
		AND OYA_TOKUI.TOKUISAKI_CD = TOKUI_HIN_EX.TOKUISAKI_CD
		AND #tmp.HINMOKU = TOKUI_HIN_EX.TOKUISAKI_SHOHIN_CD2
	INNER JOIN BC_MST_HINMOKU_KANRI HINKAN
		ON HINKAN.KAISHA_CD = @KAISHA_CD
		AND HINKAN.HINMOKU_SEQ = 
				CASE WHEN TOKUI_HIN.HINMOKU_SEQ IS NOT NULL
						THEN TOKUI_HIN.HINMOKU_SEQ
					 ELSE TOKUI_HIN_EX.HINMOKU_SEQ
				END
		AND HINKAN.DEL_FLG = 0
	INNER JOIN BC_MST_HINMOKU HIN
		ON HINKAN.KAISHA_CD = HIN.KAISHA_CD
		AND HINKAN.HINMOKU_CD = HIN.HINMOKU_CD
		AND HIN.MUKOU_FLG = 0
		AND HIN.DEL_FLG = 0
	WHERE #tmp.ERROR_MSG IS NULL
	AND TOKUI.KAISHA_CD = @KAISHA_CD
	AND TOKUI.TOKUISAKI_CD IS NOT NULL
	AND #tmp.HINMOKU_SEQ IS NULL

	--�C�i�ڃ}�X�^JAN�R�[�h
	UPDATE #tmp
	SET HINMOKU_SEQ = HINKAN.HINMOKU_SEQ
	FROM #tmp
	INNER JOIN BC_MST_HINMOKU HIN
		ON #tmp.HINMOKU = HIN.JAN_CD
		AND HIN.MUKOU_FLG = 0
		AND HIN.DEL_FLG = 0
	INNER JOIN BC_MST_HINMOKU_KANRI HINKAN
		ON HIN.KAISHA_CD = HINKAN.KAISHA_CD
		AND HIN.HINMOKU_CD = HINKAN.HINMOKU_CD
		AND HINKAN.DEL_FLG = 0
	WHERE #tmp.ERROR_MSG IS NULL
	AND HIN.KAISHA_CD = @KAISHA_CD
	AND #tmp.HINMOKU_SEQ IS NULL
	/**********************************************
    *�i��SEQ�ݒ�END
    **********************************************/

	/**********************************************
    *������ݒ�START
    **********************************************/
	--���ݒ�͊��萿����
	UPDATE #tmp
	SET SEIKYUSAKI_CD = SEIKYU.SEIKYUSAKI_CD
	FROM #tmp
	INNER JOIN BC_MST_TOKUISAKI TOKUI
		ON #tmp.TOKUISAKI_CD = TOKUI.TOKUISAKI_CD
		AND TOKUI.MUKOU_FLG = 0
		AND TOKUI.DEL_FLG = 0
	INNER JOIN BC_MST_SEIKYUSAKI SEIKYU
		ON TOKUI.KAISHA_CD = SEIKYU.KAISHA_CD
		AND TOKUI.KITEI_SEIKYUSAKI_CD = SEIKYU.SEIKYUSAKI_CD
		AND SEIKYU.MUKOU_FLG = 0
		AND SEIKYU.DEL_FLG = 0
	WHERE #tmp.ERROR_MSG IS NULL
	AND TOKUI.KAISHA_CD = @KAISHA_CD
	AND #tmp.SEIKYUSAKI_CD IS NULL
	/**********************************************
    *������ݒ�END
    **********************************************/

	/**********************************************
    *�o�א�ݒ�START
    **********************************************/
	--���ݒ�͊���o�א�
	UPDATE #tmp
	SET SHUKKASAKI_CD = SHUKKA.SHUKKASAKI_CD
	FROM #tmp
	INNER JOIN BC_MST_TOKUISAKI TOKUI
		ON #tmp.TOKUISAKI_CD = TOKUI.TOKUISAKI_CD
		AND TOKUI.MUKOU_FLG = 0
		AND TOKUI.DEL_FLG = 0
	INNER JOIN BC_MST_SHUKKASAKI SHUKKA
		ON TOKUI.KAISHA_CD = SHUKKA.KAISHA_CD
		AND TOKUI.KITEI_SHUKKASAKI_CD = SHUKKA.SHUKKASAKI_CD
		AND SHUKKA.MUKOU_FLG = 0
		AND SHUKKA.DEL_FLG = 0
	WHERE #tmp.ERROR_MSG IS NULL
	AND TOKUI.KAISHA_CD = @KAISHA_CD
	AND #tmp.SHUKKASAKI_CD IS NULL
	/**********************************************
    *�o�א�ݒ�END
    **********************************************/


	/**********************************************
    *�o�א摶�݃`�F�b�NSTART
    **********************************************/
	--�o�א�R�[�h(�w�b�_)
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_SHUKKASAKI_CD
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.SHUKKASAKI_CD IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_SHUKKASAKI SHUKKA
                    WHERE SHUKKA.KAISHA_CD = @KAISHA_CD
                    AND SHUKKA.SHUKKASAKI_CD = #tmp.SHUKKASAKI_CD
					AND SHUKKA.MUKOU_FLG = 0
                    AND SHUKKA.DEL_FLG = 0
                   )
	/**********************************************
    *�o�א摶�݃`�F�b�NEND
    **********************************************/


	/**********************************************
    *�o�ɋ敪�ݒ�START
    **********************************************/
	--���ݒ�́y�ʏ�z��ݒ�
	UPDATE #tmp
	SET SHUKKO_KBN = '01'
	WHERE ERROR_MSG IS NULL
	AND SHUKKO_KBN IS NULL
	/**********************************************
    *�o�ɋ敪�ݒ�END
    **********************************************/

	/**********************************************
    *���׏o�א�ݒ�START
    **********************************************/
	--���ݒ�̓w�b�_�̏o�א��ݒ�
	UPDATE #tmp
	SET DTL_SHUKKASAKI_CD = SHUKKASAKI_CD
	WHERE ERROR_MSG IS NULL
	AND DTL_SHUKKASAKI_CD IS NULL
	/**********************************************
    *���׏o�א�ݒ�END
    **********************************************/

	/**********************************************
    *���בq�ɐݒ�START
    **********************************************/
	--���ݒ�̓w�b�_�̑q�ɂ�ݒ�
	UPDATE #tmp
	SET DTL_SOKO_CD = SOKO_CD
	WHERE ERROR_MSG IS NULL
	AND DTL_SOKO_CD IS NULL
	/**********************************************
    *���בq�ɐݒ�END
    **********************************************/

	/**********************************************
    *�󒍓��ݒ�START
    **********************************************/
	--���ݒ�̓V�X�e�����t
	UPDATE #tmp
	SET JUCHU_DATE = CONVERT(DATE, SYSDATETIME())
	WHERE ERROR_MSG IS NULL
	AND JUCHU_DATE IS NULL
	/**********************************************
    *�󒍓��ݒ�END
    **********************************************/

	/**********************************************
    *�w�b�_�o�ח\����ݒ�START
    **********************************************/
	--���ݒ�͊���Ŏw��[�i������o�א惊�[�h�^�C�����t�Z
	--���ݒ�͊���o�א�
	DECLARE @LEAD_TIME INT = 0
	DECLARE @SHITEI_NOHIN_DATE DATETIME
	DECLARE @SHUKKASAKI_CD NVARCHAR(15)
	--�J�[�\��
	DECLARE CUR_LEAD_TIME CURSOR LOCAL FOR
	SELECT 
		SHUKKAEX.LEAD_TIME,
		#tmp.SHITEI_NOHIN_DATE,
		#tmp.SHUKKASAKI_CD
	FROM
		#tmp
	LEFT JOIN BC_MST_SHUKKASAKI_EX SHUKKAEX
		ON SHUKKAEX.KAISHA_CD = @KAISHA_CD
		AND SHUKKAEX.SHUKKASAKI_CD = #tmp.SHUKKASAKI_CD
	WHERE #tmp.ERROR_MSG IS NULL
	AND #tmp.SHUKKA_YOTEI_DATE IS NULL

	OPEN CUR_LEAD_TIME		
	FETCH NEXT FROM CUR_LEAD_TIME
		INTO @LEAD_TIME ,
			@SHITEI_NOHIN_DATE,
			@SHUKKASAKI_CD
	WHILE @@FETCH_STATUS = 0 BEGIN
			
		UPDATE #tmp	
			SET SHUKKA_YOTEI_DATE = CONVERT(VARCHAR(8),HOLIDAY_COUNT.SHUKKA_YOTEI_DATE,112)
		FROM 
			#tmp
			LEFT JOIN
			BC_MST_SHUKKASAKI_EX SHUKKAEX
			ON SHUKKAEX.KAISHA_CD = @KAISHA_CD
			AND SHUKKAEX.SHUKKASAKI_CD = #tmp.SHUKKASAKI_CD
			LEFT JOIN (
			SELECT 
			KAISHA_CD
			,MAX(DATE) AS SHUKKA_YOTEI_DATE 
			FROM 
			BC_MST_EIGYO_DATE
			WHERE 
			DATE <= DATEADD(dd, -ISNULL(@LEAD_TIME,0), @SHITEI_NOHIN_DATE) 
			AND HOLIDAY_FLG = 0
			GROUP BY KAISHA_CD
			) HOLIDAY_COUNT
			ON SHUKKAEX.KAISHA_CD = HOLIDAY_COUNT.KAISHA_CD 
			WHERE
			SHUKKAEX.KAISHA_CD = @KAISHA_CD
			AND #tmp.SHUKKASAKI_CD = @SHUKKASAKI_CD
		FETCH NEXT FROM CUR_LEAD_TIME
		INTO @LEAD_TIME ,
			@SHITEI_NOHIN_DATE,
			@SHUKKASAKI_CD
		END
	CLOSE CUR_LEAD_TIME
	DEALLOCATE CUR_LEAD_TIME
	/**********************************************
    *�w�b�_�o�ח\����ݒ�END
    **********************************************/

	/**********************************************
    *���׏o�ח\����ݒ�START
    **********************************************/
	--���ݒ�̓w�b�_�̏o�ח\���
	UPDATE #tmp
	SET DTL_SHUKKA_YOTEI_DATE = SHUKKA_YOTEI_DATE
	WHERE ERROR_MSG IS NULL
	AND DTL_SHUKKA_YOTEI_DATE IS NULL
	/**********************************************
    *���׏o�ח\����ݒ�END
    **********************************************/

	/**********************************************
    *���א�������ݒ�START
    **********************************************/
	--���ݒ�͖��ׂ̏o�ח\���
	UPDATE #tmp
	SET DTL_SEIKYU_KIJUN_DATE = DTL_SHUKKA_YOTEI_DATE
	WHERE ERROR_MSG IS NULL
	AND DTL_SEIKYU_KIJUN_DATE IS NULL
	/**********************************************
    *���א�������ݒ�END
    **********************************************/

	/**********************************************
    *���׎w��[�i���ݒ�START
    **********************************************/
	--���ݒ�̓w�b�_�̎w��[�i��
	UPDATE #tmp
	SET DTL_SHITEI_NOHIN_DATE = SHITEI_NOHIN_DATE
	WHERE ERROR_MSG IS NULL
	AND DTL_SHITEI_NOHIN_DATE IS NULL
	/**********************************************
    *���׎w��[�i���ݒ�END
    **********************************************/

	/**********************************************
    *����m��敪�ݒ�START
    **********************************************/
	--���ݒ肩�󒍋敪�u�\��v�́y����z���́y�m��z��ݒ�
	UPDATE #tmp
	SET SUITEI_KAKUTEI_KBN = CASE WHEN JUCHU_KBN = '02'
									THEN '01'	--����
								   ELSE '02'	--�m��
							 END
	WHERE ERROR_MSG IS NULL
	AND SUITEI_KAKUTEI_KBN IS NULL

	/**********************************************
    *����m��敪�ݒ�START
    **********************************************/

	/**********************************************
    *������Ԑݒ�START
    **********************************************/
	--�@���ݒ肩�y�m��z�́y�����z
	UPDATE #tmp
	SET HIKIATE_STATE = '02'
	WHERE ERROR_MSG IS NULL
	AND HIKIATE_STATE IS NULL
	AND SUITEI_KAKUTEI_KBN = '02'

	--�A���ݒ肩�y����z�͕i�ڃ}�X�^�̈����������
	UPDATE #tmp
	SET HIKIATE_STATE = HIN.STD_HIKIATE_KBN
	FROM #tmp
	INNER JOIN BC_MST_HINMOKU_KANRI HINKAN
		ON HINKAN.HINMOKU_SEQ = #tmp.HINMOKU_SEQ
	INNER JOIN BC_MST_HINMOKU HIN
		ON HIN.KAISHA_CD = HINKAN.KAISHA_CD
		AND HIN.HINMOKU_CD = HINKAN.HINMOKU_CD
	WHERE #tmp.ERROR_MSG IS NULL
	AND #tmp.HIKIATE_STATE IS NULL
	AND #tmp.HINMOKU_SEQ IS NOT NULL
	AND #tmp.SUITEI_KAKUTEI_KBN = '01'
	AND HINKAN.KAISHA_CD = @KAISHA_CD
	/**********************************************
    *������Ԑݒ�END
    **********************************************/

	/**********************************************
    *�ېŋ敪�ݒ�START
    **********************************************/
	--���ݒ�͎����}�X�^�̎󒍏���ŋ敪����ېł̏ꍇ�A��ې�
	--���͉ې�
	UPDATE #tmp
	SET KAZEI_KBN = CASE WHEN TORIHIKI.JUCHU_SHOHIZEI_KBN = 'M1'
							THEN '02'
						 ELSE '01'
					 END
	FROM #tmp
	INNER JOIN BC_MST_TOKUISAKI TOKUI
		ON #tmp.TOKUISAKI_CD = TOKUI.TOKUISAKI_CD
		AND TOKUI.MUKOU_FLG = 0
		AND TOKUI.DEL_FLG = 0
	INNER JOIN BC_MST_TORIHIKISAKI TORIHIKI
		ON TOKUI.KAISHA_CD = TORIHIKI.KAISHA_CD
		AND TOKUI.TOKUISAKI_CD = TORIHIKI.TORIHIKISAKI_CD
		AND TORIHIKI.MUKOU_FLG = 0
		AND TORIHIKI.DEL_FLG = 0
	WHERE #tmp.ERROR_MSG IS NULL
	AND TOKUI.KAISHA_CD = @KAISHA_CD
	AND #tmp.KAZEI_KBN IS NULL
	/**********************************************
    *�ېŋ敪�ݒ�END
    **********************************************/
	/*===============================���͏��̉��HEND===============================*/

	/*===============================���R�[�h�P�ʃG���[�`�F�b�NSTART===============================*/
	/**********************************************
    *�K�{�`�F�b�NSTART
    **********************************************/
	--��{�I�ȕK�{�`�F�b�N
	UPDATE #tmp
	SET #tmp.ERROR_MSG = 
		CASE --�󒍋敪���ݒ�
			 WHEN JUCHU_KBN IS NULL
					THEN @ERR_MSG_MANDATORY_FIELD + @FLD_NM_JUCHU_KBN
			 --���Ӑ斢�ݒ�
			 WHEN TOKUISAKI_CD IS NULL
					THEN @ERR_MSG_MANDATORY_FIELD + @FLD_NM_TOKUISAKI_CD
			 --���Ӑ�`�[No���ݒ�
			 WHEN TOKUISAKI_DENPYO_NO IS NULL
					THEN @ERR_MSG_MANDATORY_FIELD + @FLD_NM_TOKUISAKI_DENPYO_NO			
			 --�����斢�ݒ肩���Ӑ�Ɋ��萿���悪���݂��Ȃ�
			 WHEN SEIKYUSAKI_CD IS NULL
					THEN @ERR_MSG_MANDATORY_FIELD + @FLD_NM_SEIKYUSAKI_CD
			 --�a���a����ړ��q�ɖ��ݒ肩�A�󒍋敪�y�ړ��z�܂��͏o�ɋ敪�y�a���蔄��z�y�a���o�Ɂz
			 WHEN AZUKE_AZUKARI_IDO_SOKO_CD IS NULL AND (JUCHU_KBN = '03' OR (JUCHU_KBN = '01' AND SHUKKO_KBN IN ('03', '06')))
					THEN @ERR_MSG_MANDATORY_FIELD + @FLD_NM_AZUKE_AZUKARI_IDO_SOKO_CD
			 --�i�ږ��ݒ�
			 WHEN HINMOKU IS NULL
					THEN @ERR_MSG_MANDATORY_FIELD + @FLD_NM_HINMOKU
			 --�i�ڂɑ΂���Y���i�ڂ����݂��Ȃ�
			 WHEN HINMOKU_SEQ IS NULL
					THEN @ERR_MSG_NOT_EXIST_HINMOKU
			 --���ׂ̏o�א斢�ݒ肩�A�󒍋敪�y�{�󒍁E�ړ��z
			 WHEN DTL_SHUKKASAKI_CD IS NULL AND (JUCHU_KBN ='01' OR JUCHU_KBN ='03')
					THEN @ERR_MSG_MANDATORY_FIELD + @FLD_NM_SHUKKASAKI_CD
			 --���l(����)���ݒ�ecbeing�̍sNo(�o�׎��јA�g�ɕK�v�Ȃ��߁j
			 WHEN DTL_BIKO IS NULL
					THEN @ERR_MSG_MANDATORY_FIELD + @FLD_NM_DTL_BIKO
		END
	WHERE #tmp.ERROR_MSG IS NULL

	--�����t���K�{�`�F�b�N
	--�@�O�ݑΉ�
	--����悪�O�݂̏ꍇ�A�����ʉݒP���͕K�{
	UPDATE #tmp
	SET #tmp.ERROR_MSG = CASE WHEN TORI_GAIKA.TUKA_CD <> @TUKA_CD AND TORIHIKISAKI_TUKA_TANKA IS NULL
									THEN @ERR_MSG_MANDATORY_FIELD + @FLD_NM_TORIHIKISAKI_TUKA_TANKA
						 END
	FROM #tmp
	INNER JOIN BC_MST_TOKUISAKI TOKUI
		ON #tmp.TOKUISAKI_CD = TOKUI.TOKUISAKI_CD
		AND TOKUI.MUKOU_FLG = 0
		AND TOKUI.DEL_FLG = 0
	INNER JOIN BC_MST_TORIHIKISAKI TORIHIKI
		ON TOKUI.KAISHA_CD = TORIHIKI.KAISHA_CD
		AND TOKUI.TOKUISAKI_CD = TORIHIKI.TORIHIKISAKI_CD
		AND TORIHIKI.MUKOU_FLG = 0
		AND TORIHIKI.DEL_FLG = 0
	INNER JOIN BC_MST_TORIHIKISAKI_GAIKA TORI_GAIKA
		ON TORI_GAIKA.KAISHA_CD = TORIHIKI.KAISHA_CD
		AND TORI_GAIKA.TORIHIKISAKI_CD = TORIHIKI.TORIHIKISAKI_CD
		AND TORI_GAIKA.MUKOU_FLG = 0
		AND TORI_GAIKA.DEL_FLG = 0
	WHERE #tmp.ERROR_MSG IS NULL
	AND TOKUI.KAISHA_CD = @KAISHA_CD

	--�A�i�ڊ֌W
	UPDATE #tmp
	SET #tmp.ERROR_MSG = 
		CASE --�݌ɊǗ��i�̏ꍇ�ɁA�q�ɖ��ݒ�
			 WHEN #tmp.DTL_SOKO_CD IS NULL AND HIN.ZAIKO_KANRI_FLG = 1
					THEN @ERR_MSG_MANDATORY_FIELD + @FLD_NM_SOKO_CD
			 --�{�󒍂����b�g���A�o�������ݒ�̏ꍇ�ɁA�W�������Ȃ�
			 WHEN JUCHU_KBN ='01' AND #tmp.LOT_NUM IS NULL AND #tmp.BARA_NUM IS NULL AND HIN.STD_IRISU IS NULL
					THEN @ERR_MSG_MANDATORY_FIELD + @FLD_NM_LOT_NUM + NCHAR(13) + @FLD_NM_BARA_NUM
		END
	FROM #tmp
	INNER JOIN BC_MST_HINMOKU_KANRI HINKAN
		ON HINKAN.HINMOKU_SEQ = #tmp.HINMOKU_SEQ
	INNER JOIN BC_MST_HINMOKU HIN
		ON HIN.KAISHA_CD = HINKAN.KAISHA_CD
		AND HIN.HINMOKU_CD = HINKAN.HINMOKU_CD
	WHERE #tmp.ERROR_MSG IS NULL
	AND HINKAN.KAISHA_CD = @KAISHA_CD
	/**********************************************
    *�K�{�`�F�b�NEND
    **********************************************/

	/**********************************************
    *����ʉ݃`�F�b�NSTART
    **********************************************/
	UPDATE #tmp
	SET ERROR_MSG = @ERR_MSG_DIFFERENT_TUKA + @FLD_NM_TOKUISAKI_CD + NCHAR(13) + @FLD_NM_SEIKYUSAKI_CD
	FROM #tmp tmp
	LEFT JOIN BC_MST_TORIHIKISAKI_GAIKA TOKUISAKI
		ON TOKUISAKI.KAISHA_CD = @KAISHA_CD
		AND TOKUISAKI.TORIHIKISAKI_CD = tmp.TOKUISAKI_CD
		AND TOKUISAKI.DEL_FLG = 0
	LEFT JOIN BC_MST_TORIHIKISAKI_GAIKA SEIKYUSAKI
		ON SEIKYUSAKI.KAISHA_CD = @KAISHA_CD
		AND SEIKYUSAKI.TORIHIKISAKI_CD = tmp.SEIKYUSAKI_CD
		AND SEIKYUSAKI.DEL_FLG = 0
	WHERE ERROR_MSG IS NULL
	AND TOKUISAKI.TUKA_CD <> SEIKYUSAKI.TUKA_CD

	/**********************************************
    *����ʉ݃`�F�b�NSTART
    **********************************************/

	/**********************************************
    *�Œ�l�`�F�b�NSTART
    **********************************************/
	--�󒍋敪�y�{�󒍁z�A�o�ɋ敪�y�ʏ�z�ł��邱��
	UPDATE #tmp
	SET ERROR_MSG = @ERR_MSG_CANNOT_USE_CODE + @FLD_NM_JUCHU_KBN			
	WHERE ERROR_MSG IS NULL
	AND JUCHU_KBN <> '01'

	UPDATE #tmp
	SET ERROR_MSG = @ERR_MSG_CANNOT_USE_CODE + @FLD_NM_SHUKKO_KBN		
	WHERE ERROR_MSG IS NULL
	AND SHUKKO_KBN <> '01'

	--�q�ɃR�[�h"000001001"�ł��邱��
	UPDATE #tmp
	SET ERROR_MSG = @ERR_MSG_CANNOT_USE_CODE + @FLD_NM_SOKO_CD		
	WHERE ERROR_MSG IS NULL
	AND SOKO_CD <> '000001001'

	--����/�m��敪
	UPDATE #tmp
	SET ERROR_MSG = @ERR_MSG_CANNOT_USE_CODE + @FLD_NM_SUITEI_KAKUTEI_KBN	
	WHERE ERROR_MSG IS NULL
	AND SUITEI_KAKUTEI_KBN <> '02'

	/**********************************************
    *�Œ�l�`�F�b�NEND
    **********************************************/

	/**********************************************
    *�󒍋敪�ɂ������`�F�b�NSTART
    **********************************************/
	--�\��`�[
	--�o�ɋ敪�y�ʏ�z�A����m��敪�y����z�ł��邱��
	UPDATE #tmp
	SET ERROR_MSG = 
			CASE WHEN SHUKKO_KBN <> '01'
					THEN @ERR_MSG_CANNOT_USE_CODE + @FLD_JUCHU_KBN_YOYAKU + NCHAR(13) + @FLD_NM_SHUKKO_KBN
				 WHEN SUITEI_KAKUTEI_KBN <> '01'
					THEN @ERR_MSG_CANNOT_USE_CODE + @FLD_JUCHU_KBN_YOYAKU + NCHAR(13) + @FLD_NM_SUITEI_KAKUTEI_KBN
			END
	WHERE ERROR_MSG IS NULL
	AND JUCHU_KBN = '02'
	
	--�q�Ɉړ�
	--�o�ɋ敪�y�q�Ɉړ��z�ł��邱��
	UPDATE #tmp
	SET ERROR_MSG = CASE WHEN SHUKKO_KBN <> '40'
							THEN @ERR_MSG_CANNOT_USE_CODE + @FLD_JUCHU_KBN_SOKO_IDO + NCHAR(13) + @FLD_NM_SHUKKO_KBN
					END
	WHERE ERROR_MSG IS NULL
	AND JUCHU_KBN = '03'
	
	--�ړ����ƈړ���q�ɂ������ꍇ�G���[
	UPDATE #tmp
	SET ERROR_MSG = CASE WHEN SOKO_CD = AZUKE_AZUKARI_IDO_SOKO_CD
							THEN @ERR_MSG_SOKO_IDO_SOKO
					END
	WHERE ERROR_MSG IS NULL
	AND JUCHU_KBN = '03'
	
	--�ړ����ƈړ���ǂ�����X�܂̏ꍇ�G���[
	UPDATE #tmp
    SET #tmp.ERROR_MSG = 
			CASE WHEN MOTO_TOKUI_EX.TORIHIKI_KEITAI_KBN IN ('4','5') AND SAKI_TOKUI_EX.TORIHIKI_KEITAI_KBN IN ('4','5')
					THEN @ERR_MSG_SOKO_TENPO
			END
	FROM #tmp
	LEFT JOIN BC_MST_TORIHIKISAKI MOTO_TORI
		ON MOTO_TORI.TORIHIKISAKI_CD = #tmp.SOKO_CD
		AND MOTO_TORI.KAISHA_CD = @KAISHA_CD
		AND MOTO_TORI.TOKUISAKI_FLG = 1
	LEFT JOIN BC_MST_TOKUISAKI MOTO_TOKUI
		ON MOTO_TOKUI.TOKUISAKI_CD = MOTO_TORI.TORIHIKISAKI_CD
		AND MOTO_TOKUI.KAISHA_CD = MOTO_TORI.KAISHA_CD
		AND MOTO_TOKUI.MUKOU_FLG = 0
		AND MOTO_TOKUI.DEL_FLG = 0
	LEFT JOIN BC_MST_TOKUISAKI_EX MOTO_TOKUI_EX
		ON MOTO_TOKUI_EX.TOKUISAKI_CD = MOTO_TOKUI.TOKUISAKI_CD
		AND MOTO_TOKUI_EX.KAISHA_CD = MOTO_TOKUI.KAISHA_CD
		
	LEFT JOIN BC_MST_TORIHIKISAKI SAKI_TORI
		ON SAKI_TORI.TORIHIKISAKI_CD = #tmp.AZUKE_AZUKARI_IDO_SOKO_CD
		AND SAKI_TORI.KAISHA_CD = @KAISHA_CD
		AND SAKI_TORI.TOKUISAKI_FLG = 1
	LEFT JOIN BC_MST_TOKUISAKI SAKI_TOKUI
		ON SAKI_TOKUI.TOKUISAKI_CD = SAKI_TORI.TORIHIKISAKI_CD
		AND SAKI_TOKUI.KAISHA_CD = SAKI_TORI.KAISHA_CD
		AND SAKI_TOKUI.MUKOU_FLG = 0
		AND SAKI_TOKUI.DEL_FLG = 0
	LEFT JOIN BC_MST_TOKUISAKI_EX SAKI_TOKUI_EX
		ON SAKI_TOKUI_EX.TOKUISAKI_CD = SAKI_TOKUI.TOKUISAKI_CD
		AND SAKI_TOKUI_EX.KAISHA_CD = SAKI_TOKUI.KAISHA_CD
	WHERE #tmp.ERROR_MSG IS NULL
	AND #tmp.JUCHU_KBN = '03'

	
	/**********************************************
    *�󒍋敪�ɂ������`�F�b�NEND
    **********************************************/
	
	/**********************************************
    *�a���E�a����E�\��E�q�Ɉړ��E�q�ɋ敪�`�F�b�NSTART
    **********************************************/
	--�@�݌ɊǗ��i�`�F�b�N
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_CANNOT_ZAIKOKNARI + @FLD_NM_HINMOKU
	FROM #tmp	
	WHERE #tmp.ERROR_MSG IS NULL
	AND (#tmp.SHUKKO_KBN IN ('03', '04', '06', '07')
			OR #tmp.JUCHU_KBN IN ('02', '03'))
	AND NOT EXISTS (SELECT *
	                FROM BC_MST_HINMOKU_KANRI HINKAN
				    INNER JOIN BC_MST_HINMOKU HIN
						ON HIN.KAISHA_CD = HINKAN.KAISHA_CD
						AND HIN.HINMOKU_CD = HINKAN.HINMOKU_CD
					WHERE HINKAN.KAISHA_CD = @KAISHA_CD
					AND HINKAN.HINMOKU_SEQ = #tmp.HINMOKU_SEQ
					AND HIN.ZAIKO_KANRI_FLG = 1
				   )

	--�A�a����o�ɁA�a�����㎞�̑q�ɋ敪�`�F�b�N
	UPDATE #tmp
    SET #tmp.ERROR_MSG = 
			CASE --�a����o�Ɏ��ɁA�a����q�ɂ��w�肳��Ă��Ȃ�
				 WHEN #tmp.SHUKKO_KBN = '04' AND SOKO.SOKO_KBN <> '02'
						THEN @ERR_MSG_AZUKE_AZUKARI_SOKO + @FLD_NM_SOKO_CD
				 --�a�����㎞�ɁA�a���q�ɂ��w�肳��Ă��Ȃ�
				 WHEN #tmp.SHUKKO_KBN = '07' AND SOKO.SOKO_KBN <> '03'
						THEN @ERR_MSG_AZUKE_AZUKARI_SOKO + @FLD_NM_SOKO_CD
			 END
	FROM #tmp
	INNER JOIN BC_MST_SOKO SOKO
		ON #tmp.DTL_SOKO_CD = SOKO.SOKO_CD
	WHERE #tmp.ERROR_MSG IS NULL
	AND SOKO.KAISHA_CD = @KAISHA_CD
	AND #tmp.SHUKKO_KBN IN ('04', '07')

	--�B�a���蔄��A�a���o�Ɏ��́y�a���a����ړ��q�Ɂz�q�ɋ敪�`�F�b�N
	UPDATE #tmp
    SET #tmp.ERROR_MSG = 
			CASE --�a���蔄�㎞�ɁA�y�a���a����ړ��q�Ɂz�ɗa����q�ɂ��w�肳��Ă��Ȃ�
				 WHEN #tmp.SHUKKO_KBN = '03' AND SOKO.SOKO_KBN <> '02'
						THEN @ERR_MSG_AZUKE_AZUKARI_SOKO + @FLD_NM_AZUKE_AZUKARI_IDO_SOKO_CD
				 --�a�����㎞�ɁA�y�a���a����ړ��q�Ɂz�ɗa���q�ɂ��w�肳��Ă��Ȃ�
				 WHEN #tmp.SHUKKO_KBN = '06' AND SOKO.SOKO_KBN <> '03'
						THEN @ERR_MSG_AZUKE_AZUKARI_SOKO + @FLD_NM_AZUKE_AZUKARI_IDO_SOKO_CD
			 END
	FROM #tmp
	INNER JOIN BC_MST_SOKO SOKO
		ON #tmp.AZUKE_AZUKARI_IDO_SOKO_CD = SOKO.SOKO_CD
	WHERE #tmp.ERROR_MSG IS NULL
	AND SOKO.KAISHA_CD = @KAISHA_CD
	AND #tmp.SHUKKO_KBN IN ('03', '06')

	--�C�o�ɋ敪���u�ʏ�v���́A�q�ɋ敪�u�ʏ�v�`�F�b�N
	UPDATE #tmp
    SET #tmp.ERROR_MSG = 
			CASE WHEN SOKO.SOKO_KBN <> '01'
					THEN @ERR_MSG_TUJOU_SHUKKO_SOKO + @FLD_NM_SOKO_CD + NCHAR(13) + #tmp.DTL_SOKO_CD
			END
	FROM #tmp
	INNER JOIN BC_MST_SOKO SOKO
		ON SOKO.SOKO_CD = #tmp.DTL_SOKO_CD
	WHERE #tmp.ERROR_MSG IS NULL
	AND SOKO.KAISHA_CD = @KAISHA_CD
	AND #tmp.SHUKKO_KBN = '01'

	--�D�q�Ɉړ����A�ړ����A�ړ���̑q�ɋ敪���u�ʏ�v�ł��邱��
	UPDATE #tmp
    SET #tmp.ERROR_MSG = 
			CASE WHEN MOTO_SOKO.SOKO_KBN <> '01'
					THEN @ERR_MSG_SOKO_IDO_SHUKKO_KBN + @FLD_NM_SOKO_CD
			    WHEN SAKI_SOKO.SOKO_KBN <> '01'
					THEN @ERR_MSG_SOKO_IDO_SHUKKO_KBN + @FLD_NM_AZUKE_AZUKARI_IDO_SOKO_CD
			END
	FROM #tmp
	INNER JOIN BC_MST_SOKO MOTO_SOKO
		ON MOTO_SOKO.SOKO_CD = #tmp.DTL_SOKO_CD
	INNER JOIN BC_MST_SOKO SAKI_SOKO
		ON SAKI_SOKO.SOKO_CD = #tmp.AZUKE_AZUKARI_IDO_SOKO_CD
	WHERE #tmp.ERROR_MSG IS NULL
	AND MOTO_SOKO.KAISHA_CD = @KAISHA_CD
	AND SAKI_SOKO.KAISHA_CD = @KAISHA_CD
	AND #tmp.JUCHU_KBN = '03'

	/**********************************************
    *�a���E�a����E�q�Ɉړ��E�q�ɋ敪�`�F�b�NEND
    **********************************************/

	/**********************************************
    *�����`�F�b�NSTART
    **********************************************/
	UPDATE #tmp
	SET #tmp.ERROR_MSG = 
		CASE --�w��[�i����
			 WHEN SHITEI_NOHIN_JIKOKU IS NOT NULL AND LEN(SHITEI_NOHIN_JIKOKU) > 20
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_SHITEI_NOHIN_JIKOKU
			 --���Ӑ�`�[�ԍ�
			 WHEN TOKUISAKI_DENPYO_NO IS NOT NULL AND LEN(TOKUISAKI_DENPYO_NO) > 20
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_TOKUISAKI_DENPYO_NO
			 --���Ӑ攭���ԍ�
			 WHEN TOKUISAKI_HACCHU_NO IS NOT NULL AND LEN(TOKUISAKI_HACCHU_NO) > 20
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_TOKUISAKI_HACCHU_NO
			 --���ރR�[�h
			 WHEN BUNRUI_CD IS NOT NULL AND LEN(BUNRUI_CD) > 20
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_BUNRUI_CD
			 --���ꖼ
			 WHEN URIBA_NM IS NOT NULL AND LEN(URIBA_NM) > 20
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_URIBA_NM
			 --�S���Җ�
			 WHEN TANTOSHA_NM IS NOT NULL AND LEN(TANTOSHA_NM) > 40
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_TANTOSHA_NM
			 --�����ԍ�
			 WHEN NAISEN_NO IS NOT NULL AND LEN(NAISEN_NO) > 20
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_NAISEN_NO
			 --���l
			 WHEN BIKO IS NOT NULL AND LEN(BIKO) > 100
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_BIKO
			 --�󒍃R�����g
			 WHEN JUCHU_COMMENT IS NOT NULL AND LEN(JUCHU_COMMENT) > 100
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_JUCHU_COMMENT
			 --�q�Ɍ����R�����g
			 WHEN SOKO_COMMENT IS NOT NULL AND LEN(SOKO_COMMENT) > 100
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_SOKO_COMMENT
			 --�E�v
			 WHEN TEKIYO IS NOT NULL AND LEN(TEKIYO) > 500
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_TEKIYO
			 --���l(����)
			 WHEN DTL_BIKO IS NOT NULL AND LEN(DTL_BIKO) > 100
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_DTL_BIKO
		END
	WHERE #tmp.ERROR_MSG IS NULL
	/**********************************************
    *�����`�F�b�NEND
    **********************************************/

	/**********************************************
    *���t�`�F�b�NSTART
    **********************************************/
	UPDATE #tmp
	SET #tmp.ERROR_MSG = 
		CASE --�󒍓�
			 WHEN ISDATE(JUCHU_DATE) != 1
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_JUCHU_DATE
			 --�o�ח\���(�w�b�_)
			 WHEN ISDATE(SHUKKA_YOTEI_DATE) != 1
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_HDR_SHUKKA_YOTEI_DATE
			 --�w��[�i��(�w�b�_)
			 WHEN SHITEI_NOHIN_DATE IS NOT NULL AND ISDATE(SHITEI_NOHIN_DATE) != 1
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_SHITEI_NOHIN_DATE
			 --�������(�w�b�_)
			 WHEN HDR_SEIKYU_KIJUN_DATE IS NOT NULL AND ISDATE(HDR_SEIKYU_KIJUN_DATE) != 1
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_SEIKYU_KIJUN_DATE
			 --�\��������
			 WHEN YOYAKU_KAIHO_KIGEN IS NOT NULL AND ISDATE(YOYAKU_KAIHO_KIGEN) != 1
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_YOYAKU_KAIHO_KIGEN
			 --�o�ח\���(����)
			 WHEN ISDATE(DTL_SHUKKA_YOTEI_DATE) != 1
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_DTL_SHUKKA_YOTEI_DATE
			 --�w��[�i��(����)
			 WHEN DTL_SHITEI_NOHIN_DATE IS NOT NULL AND ISDATE(DTL_SHITEI_NOHIN_DATE) != 1
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_SHITEI_NOHIN_DATE
			 --�������(����)
			 WHEN DTL_SEIKYU_KIJUN_DATE IS NOT NULL AND ISDATE(DTL_SEIKYU_KIJUN_DATE) != 1
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_SEIKYU_KIJUN_DATE
		END
	WHERE #tmp.ERROR_MSG IS NULL

    --�󒍓�<=�o�ח\����`�F�b�N
    UPDATE #tmp
	SET #tmp.ERROR_MSG = 
			CASE WHEN DATEDIFF(DD, #tmp.JUCHU_DATE, #tmp.SHUKKA_YOTEI_DATE) < 0
						THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_JUCHU_DATE + NCHAR(13) + '��' + @FLD_NM_HDR_SHUKKA_YOTEI_DATE
				 WHEN DATEDIFF(DD, #tmp.JUCHU_DATE, #tmp.DTL_SHUKKA_YOTEI_DATE) < 0
						THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_JUCHU_DATE + NCHAR(13) + '��' + @FLD_NM_DTL_SHUKKA_YOTEI_DATE
			 END
	WHERE #tmp.ERROR_MSG IS NULL
	/**********************************************
    *���t�`�F�b�NEND
    **********************************************/

	/**********************************************
    *���l�`�F�b�NSTART
    **********************************************/
	UPDATE #tmp
	SET #tmp.ERROR_MSG = 
		CASE --���b�g��
			 WHEN LOT_NUM IS NOT NULL AND isnumeric(LOT_NUM) != 1
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_LOT_NUM
			 --�o����
			 WHEN BARA_NUM IS NOT NULL AND isnumeric(BARA_NUM) != 1
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_BARA_NUM
			 --�|��(%):�T���v���̏ꍇ�A�`�F�b�N�ΏۊO
			 WHEN SAMPLE_SHUKKA_FLG = 0 AND KAKERITU IS NOT NULL AND isnumeric(KAKERITU) != 1
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_KAKERITU
			 --�����ʉݒP��:�T���v���̏ꍇ�A�`�F�b�N�ΏۊO
			 WHEN SAMPLE_SHUKKA_FLG = 0 AND TORIHIKISAKI_TUKA_TANKA IS NOT NULL AND isnumeric(TORIHIKISAKI_TUKA_TANKA) != 1 
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_TORIHIKISAKI_TUKA_TANKA
			 --���[�g
			 WHEN RATE IS NOT NULL AND isnumeric(RATE) != 1
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_RATE
		END
	WHERE #tmp.ERROR_MSG IS NULL
	/**********************************************
    *���l�`�F�b�NEND
    **********************************************/

	/**********************************************
    *���l�͈̓`�F�b�NSTART
    **********************************************/
	UPDATE #tmp
	SET #tmp.ERROR_MSG = 
		CASE --���b�g��
			 WHEN (CONVERT(float,LOT_NUM) < 0 
         			OR (@SURYO_KETA='3' AND 9999.999< CONVERT(float,LOT_NUM))
         			OR (@SURYO_KETA='2' AND 9999.99< CONVERT(float,LOT_NUM))
         			OR (@SURYO_KETA='1' AND 9999.9< CONVERT(float,LOT_NUM))
         			OR (@SURYO_KETA='0' AND 9999< CONVERT(float,LOT_NUM)))
						THEN @ERR_MSG_INVALID_NUMBER + @FLD_NM_LOT_NUM
			 --�o����
			 WHEN (CONVERT(float,BARA_NUM) < 0 
         			OR (@SURYO_KETA='3' AND 9999.999< CONVERT(float,BARA_NUM))
         			OR (@SURYO_KETA='2' AND 9999.99< CONVERT(float,BARA_NUM))
         			OR (@SURYO_KETA='1' AND 9999.9< CONVERT(float,BARA_NUM))
         			OR (@SURYO_KETA='0' AND 999999< CONVERT(float,BARA_NUM)))
						THEN @ERR_MSG_INVALID_NUMBER + @FLD_NM_BARA_NUM
			 --�|��(%)
			 WHEN (CONVERT(float,KAKERITU) < 0
					OR (99.9<CONVERT(float, KAKERITU)))
						THEN @ERR_MSG_INVALID_NUMBER + @FLD_NM_KAKERITU
			 --�����ʉݒP��(���z�̃}�C�i�X�o�^�͖��Ȃ�)
			 WHEN (9999999999.999 < CONVERT(float,TORIHIKISAKI_TUKA_TANKA))
						THEN @ERR_MSG_INVALID_NUMBER + @FLD_NM_TORIHIKISAKI_TUKA_TANKA
			 --���[�g
			 WHEN (CONVERT(float,RATE) < 0
					OR (99999.999<CONVERT(float, RATE)))
						THEN @ERR_MSG_INVALID_NUMBER + @FLD_NM_RATE
		END
	WHERE #tmp.ERROR_MSG IS NULL
	/**********************************************
    *���l�͈̓`�F�b�NEND
    **********************************************/

	/**********************************************
    *�}�X�^�R�[�h�l�`�F�b�NSTART
    **********************************************/
	--���Ӑ�R�[�h
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_TOKUISAKI_CD
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.TOKUISAKI_CD IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_TOKUISAKI TOKUI
                    WHERE TOKUI.KAISHA_CD = @KAISHA_CD
                    AND TOKUI.TOKUISAKI_CD = #tmp.TOKUISAKI_CD
					AND TOKUI.MUKOU_FLG = 0
                    AND TOKUI.DEL_FLG = 0
                   )

	
	--������R�[�h
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_SEIKYUSAKI_CD
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.SEIKYUSAKI_CD IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_SEIKYUSAKI SEIKYU
                    WHERE SEIKYU.KAISHA_CD = @KAISHA_CD
                    AND SEIKYU.SEIKYUSAKI_CD = #tmp.SEIKYUSAKI_CD
					AND SEIKYU.MUKOU_FLG = 0
                    AND SEIKYU.DEL_FLG = 0
                   )

	--�q�ɃR�[�h(�w�b�_)
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_SOKO_CD
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.SOKO_CD IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_SOKO SOKO
                    WHERE SOKO.KAISHA_CD = @KAISHA_CD
                    AND SOKO.SOKO_CD = #tmp.SOKO_CD
					AND SOKO.MUKOU_FLG = 0
                    AND SOKO.DEL_FLG = 0
                   )

	--�a���^�a����^�ړ��q�ɃR�[�h
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_AZUKE_AZUKARI_IDO_SOKO_CD
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.AZUKE_AZUKARI_IDO_SOKO_CD IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_SOKO SOKO
                    WHERE SOKO.KAISHA_CD = @KAISHA_CD
                    AND SOKO.SOKO_CD = #tmp.AZUKE_AZUKARI_IDO_SOKO_CD
					AND SOKO.MUKOU_FLG = 0
                    AND SOKO.DEL_FLG = 0
				   )

	--�S���҃R�[�h
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_TANTOSHA_CD
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.TANTOSHA_CD IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_SHAIN SHAIN
                    WHERE SHAIN.KAISHA_CD = @KAISHA_CD
                    AND SHAIN.SHAIN_CD = #tmp.TANTOSHA_CD
					AND SHAIN.MUKOU_FLG = 0
                    AND SHAIN.DEL_FLG = 0
				   )

	--�����R�[�h
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_TANTO_BUSHO_CD
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.TANTO_BUSHO_CD IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_BUSHO BUSHO
                    WHERE BUSHO.KAISHA_CD = @KAISHA_CD
                    AND BUSHO.BUSHO_CD = #tmp.TANTO_BUSHO_CD
					AND BUSHO.MUKOU_FLG = 0
                    AND BUSHO.DEL_FLG = 0
				   )

	--�v���W�F�N�g�R�[�h
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_PROJECT_CD
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.PROJECT_CD IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_PROJECT PROJECT
                    WHERE PROJECT.KAISHA_CD = @KAISHA_CD
                    AND PROJECT.PROJECT_CD = #tmp.PROJECT_CD
					AND PROJECT.MUKOU_FLG = 0
                    AND PROJECT.DEL_FLG = 0
				   )

	--�̔��G���A�R�[�h
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_HANBAI_AREA_CD
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.HANBAI_AREA_CD IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_HANBAI_AREA AREA
                    WHERE AREA.KAISHA_CD = @KAISHA_CD
                    AND AREA.HANBAI_AREA_CD = #tmp.HANBAI_AREA_CD
                    AND AREA.DEL_FLG = 0
				   )

	--�q�ɃR�[�h(����)
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_SOKO_CD
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.DTL_SOKO_CD IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_SOKO SOKO
                    WHERE SOKO.KAISHA_CD = @KAISHA_CD
                    AND SOKO.SOKO_CD = #tmp.DTL_SOKO_CD
					AND SOKO.MUKOU_FLG = 0
                    AND SOKO.DEL_FLG = 0
                   )

	--�o�א�R�[�h(����)
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_SHUKKASAKI_CD
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.DTL_SHUKKASAKI_CD IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_SHUKKASAKI SHUKKA
                    WHERE SHUKKA.KAISHA_CD = @KAISHA_CD
                    AND SHUKKA.SHUKKASAKI_CD = #tmp.DTL_SHUKKASAKI_CD
					AND SHUKKA.MUKOU_FLG = 0
                    AND SHUKKA.DEL_FLG = 0
                   )
	/**********************************************
    *�}�X�^�R�[�h�l�`�F�b�NEND
    **********************************************/

	/**********************************************
    *�R�[�h�}�X�^�R�[�h�l�`�F�b�NSTART
    **********************************************/
	--�󒍋敪
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_JUCHU_KBN
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.JUCHU_KBN IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_CODE_KAISHA_BETU CODE
                    WHERE CODE.KAISHA_CD = @KAISHA_CD
					AND CODE.CD_SECTION = 'M00005'
                    AND CODE.CD_KEY = #tmp.JUCHU_KBN
                    AND CODE.DEL_FLG = 0
                   )

	--�o�ɋ敪
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_SHUKKO_KBN
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.SHUKKO_KBN IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_CODE_KAISHA_BETU CODE
                    WHERE CODE.KAISHA_CD = @KAISHA_CD
					AND CODE.CD_SECTION = '000004'
                    AND CODE.CD_KEY = #tmp.SHUKKO_KBN
					AND CODE.CD_KEY <> '02'	--�����̓G���[
					AND CODE.CD_KEY <> '05'	--�ԕi�̓G���[
                    AND CODE.DEL_FLG = 0
                   )

	--�z���敪
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_HAISOU_KBN
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.HAISOU_KBN IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_CODE_KAISHA_BETU CODE
                    WHERE CODE.KAISHA_CD = @KAISHA_CD
					AND CODE.CD_SECTION = 'M00003'
                    AND CODE.CD_KEY = #tmp.HAISOU_KBN
                    AND CODE.DEL_FLG = 0
                   )

	--���ϕ��@
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_KESSAI_HOHO
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.KESSAI_HOHO IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_CODE_KAISHA_BETU CODE
                    WHERE CODE.KAISHA_CD = @KAISHA_CD
					AND CODE.CD_SECTION = 'M00004'
                    AND CODE.CD_KEY = #tmp.KESSAI_HOHO
                    AND CODE.DEL_FLG = 0
                   )

	--�[�i�敪
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_NOHIN_KBN
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.NOHIN_KBN IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_CODE_KAISHA_BETU CODE
                    WHERE CODE.KAISHA_CD = @KAISHA_CD
					AND CODE.CD_SECTION = 'M00006'
                    AND CODE.CD_KEY = #tmp.NOHIN_KBN
                    AND CODE.DEL_FLG = 0
                   )

	--���ʉ��H�敪
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_RYUTU_KAKOU_KBN
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.RYUTU_KAKOU_KBN IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_CODE_KAISHA_BETU CODE
                    WHERE CODE.KAISHA_CD = @KAISHA_CD
					AND CODE.CD_SECTION = 'M00007'
                    AND CODE.CD_KEY = #tmp.RYUTU_KAKOU_KBN
                    AND CODE.DEL_FLG = 0
                   )

	--����m��敪
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_SUITEI_KAKUTEI_KBN
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.SUITEI_KAKUTEI_KBN IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_CODE_KAISHA_BETU CODE
                    WHERE CODE.KAISHA_CD = @KAISHA_CD
					AND CODE.CD_SECTION = '000003'
                    AND CODE.CD_KEY = #tmp.SUITEI_KAKUTEI_KBN
                    AND CODE.DEL_FLG = 0
                   )

	--�������
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_HIKIATE_STATE
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.HIKIATE_STATE IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_CODE_KAISHA_BETU CODE
                    WHERE CODE.KAISHA_CD = @KAISHA_CD
					AND CODE.CD_SECTION = '000005'
                    AND CODE.CD_KEY = #tmp.HIKIATE_STATE
					AND CODE.CD_KEY NOT IN ('04', '05')	--�����A�s���������̓G���[
                    AND CODE.DEL_FLG = 0
                   )
	/**********************************************
    *�R�[�h�}�X�^�R�[�h�l�`�F�b�NEND
    **********************************************/

	/**********************************************
    *������ԃ`�F�b�NSTART
    **********************************************/
	--�a���蔄��A�a���o�ɂ̏ꍇ�A������Ԃ́u�����v�ł��邱��
	--�ړ��̏ꍇ�u���v�u�����v�ł��邱��
	--�\��`�[�̏ꍇ�A������Ԃ́u���v�u�����v�u�ꊇ�����v�ł��邱��
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_CANNOT_USE_CODE + @FLD_NM_HIKIATE_STATE
	WHERE #tmp.ERROR_MSG IS NULL
	AND ((#tmp.SHUKKO_KBN IN ('03', '06') AND #tmp.HIKIATE_STATE <> '02')
			OR (#tmp.JUCHU_KBN = '03' AND #tmp.HIKIATE_STATE NOT IN ('01', '02'))
			OR (#tmp.JUCHU_KBN ='02' AND #tmp.HIKIATE_STATE NOT IN ('01', '02', '03')))

	--������ԁu���v�u�ꊇ�����v�̏ꍇ�A����m��敪���u����v�ł��邱��
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_CANNOT_USE_CODE + @FLD_NM_HIKIATE_STATE + NCHAR(13) + @FLD_NM_SUITEI_KAKUTEI_KBN
	WHERE #tmp.ERROR_MSG IS NULL
	AND #tmp.HIKIATE_STATE IN ('01', '03')
	AND #tmp.SUITEI_KAKUTEI_KBN <> '01'
	/**********************************************
    *������ԃ`�F�b�NEND
    **********************************************/

	/**********************************************
    *�ېŋ敪�`�F�b�NSTART
    **********************************************/
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_KAZEI_KBN
	WHERE #tmp.ERROR_MSG IS NULL
	AND #tmp.KAZEI_KBN IS NOT NULL
	AND NOT EXISTS (SELECT CD_KEY
					--�ېŔ�ېł̑��A�ŗ��w����l��
	                FROM (SELECT CD_KEY
						  FROM BC_MST_CODE_KAISHA_BETU
						  WHERE KAISHA_CD = @KAISHA_CD
						  AND CD_SECTION = '000051' --�ېŋ敪
		 				  AND SUB_KEY = 0 --0�Œ�
						  AND DEL_FLG = 0
						  UNION ALL 
						  SELECT DISTINCT '9' + RIGHT('00' + CAST(CAST((TAX_RATE * 100)AS tinyint) AS nvarchar),2) AS CD_KEY --�擪��9��t��
						  FROM BC_MST_TAX MTAX
						  WHERE MTAX.KAISHA_CD = @KAISHA_CD
						  AND DATEDIFF(dd, (SELECT VALUE
											FROM BC_MST_SYSTEM
											WHERE KAISHA_CD = @KAISHA_CD
		    								AND BUNRUI_NM = 'CO'
											AND VALUE_NM = 'TAX_SITEI_START_DATE')
									   ,MTAX.START_DATE) > 0
						  AND MTAX.DEL_FLG = 0
						 ) TAX_CD   
					 WHERE TAX_CD.CD_KEY = #tmp.KAZEI_KBN
					)
	/**********************************************
    *�ېŋ敪�`�F�b�NEND
    **********************************************/

	/**********************************************
    *�\��������̐������`�F�b�NSTART
    **********************************************/
	UPDATE #tmp
	SET ERROR_MSG = 
			CASE --�`�[���폜�܂��͎������Ă���OR�\��`�[�ł͂Ȃ�OR���݂��Ȃ�
				 WHEN JHDR_Y.CANCEL_FLG = 1 OR JHDR_Y.DEL_FLG = 1 OR JHDR_EX_Y.JUCHU_KBN <> '02' OR JDTL_Y.DEL_FLG = 1
						OR JDTL_Y.JUCHU_NO IS NULL OR JDTL_Y.JUCHU_ENO IS NULL
						THEN @ERR_MSG_CANNOT_USE_YOYAKU
				 --�\��̏o�ח\��� > �󒍂̏o�ח\���
				 WHEN DATEDIFF(DAY, JDTL_Y.SHUKKA_YOTEI_DATE, #tmp.DTL_SHUKKA_YOTEI_DATE) < 0
						THEN @ERR_MSG_CANNOT_USE_YOYAKU + @FLD_NM_DTL_SHUKKA_YOTEI_DATE
				 --�i��SEQ���قȂ�
				 WHEN #tmp.HINMOKU_SEQ <> JDTL_Y.HINMOKU_SEQ
						THEN @ERR_MSG_CANNOT_USE_YOYAKU + @FLD_NM_HINMOKU
			END
	FROM #tmp
	LEFT JOIN HK_TBL_JUCHU_HDR JHDR_Y
		ON JHDR_Y.KAISHA_CD = @KAISHA_CD
		AND #tmp.YOYAKU_DENPYO_NO = JHDR_Y.JUCHU_NO
	LEFT JOIN HK_TBL_JUCHU_HDR_EX JHDR_EX_Y
		ON JHDR_EX_Y.KAISHA_CD = JHDR_Y.KAISHA_CD
		AND JHDR_EX_Y.JUCHU_NO = JHDR_Y.JUCHU_NO
	LEFT JOIN HK_TBL_JUCHU_DTL JDTL_Y
		ON JDTL_Y.KAISHA_CD = JHDR_Y.KAISHA_CD
		AND JDTL_Y.JUCHU_NO = JHDR_Y.JUCHU_NO
		AND JDTL_Y.JUCHU_ENO = #tmp.YOYAKU_DENPYO_ENO
	WHERE #tmp.ERROR_MSG IS NULL
	AND #tmp.JUCHU_KBN IN ('01', '03')
	AND #tmp.YOYAKU_DENPYO_NO IS NOT NULL
	AND #tmp.YOYAKU_DENPYO_ENO IS NOT NULL
	/**********************************************
    *�\��������̐������`�F�b�NEND
    **********************************************/
	/*===============================���R�[�h�P�ʃG���[�`�F�b�NEND===============================*/

	/*===============================���R�[�h��`�[�P�ʂɓZ�߂�START===============================*/
	--�w�b�_����v������̂ɑ΂���ID��t�^
	--�A�����ďo�����Ȃ����̂���ʂ��邽�߁A�s�ԍ�����w�b�_�ŃO���[�s���O�����p�[�e�B�V�����s�ԍ�������
	UPDATE #tmp
	SET TMP_ID = tmp2.TMP_ID
	FROM (SELECT (LINE_NO - ROW_NUMBER() OVER(PARTITION BY DENPYO_NO
														  ,JUCHU_KBN
														  ,JUCHU_DATE
														  ,SHUKKO_KBN
														  ,TOKUISAKI_CD
														  ,SHUKKASAKI_CD
														  ,SEIKYUSAKI_CD
														  ,SOKO_CD
														  ,AZUKE_AZUKARI_IDO_SOKO_CD
														  ,SHUKKA_YOTEI_DATE
														  ,SHITEI_NOHIN_DATE
														  ,SHITEI_NOHIN_JIKOKU
														  ,HAISOU_KBN
														  ,KESSAI_HOHO
														  ,HDR_GEDAIMACHI_FLG
														  ,SAMPLE_SHUKKA_FLG
														  ,HIKIATE_CHOSEI_FUYO_FLG
														  ,HDR_SEIKYU_KIJUN_DATE
														  ,TOKUISAKI_DENPYO_NO
														  ,TOKUISAKI_HACCHU_NO
														  ,BUNRUI_CD
														  ,URIBA_NM
														  ,TANTOSHA_NM
														  ,NAISEN_NO
														  ,TANTOSHA_CD
														  ,TANTO_BUSHO_CD
														  ,NOHIN_KBN
														  ,RYUTU_KAKOU_KBN
														  ,BIKO
														  ,JUCHU_COMMENT
														  ,SOKO_COMMENT
														  ,PROJECT_CD
														  ,HANBAI_AREA_CD
														  ,YOYAKU_KAIHO_KIGEN
														  ,HINMOKU					
														  ,LOT_NUM					
														  ,BARA_NUM				
														  ,SUITEI_KAKUTEI_KBN		
														  ,KAKERITU				
														  ,HIKIATE_STATE			
														  ,DTL_GEDAIMACHI_FLG		
														  ,DTL_SOKO_CD				
														  ,TEKIYO					
														  ,DTL_SHUKKASAKI_CD		
														  ,DTL_SHUKKA_YOTEI_DATE	
														  ,DTL_SHITEI_NOHIN_DATE	
														  ,DTL_SEIKYU_KIJUN_DATE	
														  ORDER BY LINE_NO)
				 ) AS TMP_ID
				 ,LINE_NO
		  FROM #tmp
		 ) AS tmp2
	WHERE #tmp.LINE_NO = tmp2.LINE_NO

	--#tmpHdr��Insert
	--TMP_ID�ƃw�b�_���ŃO���[�s���O���AGROUP_KEY�ɍs�ԍ���ݒ�
	INSERT INTO #tmpHdr
	(TMP_ID
	,GROUP_KEY
	,DENPYO_NO
	,HACCHU_NO
	,SOKO_IDO_NO
	,JUCHU_KBN
	,JUCHU_DATE
	,SHUKKO_KBN
	,TOKUISAKI_CD
	,SHUKKASAKI_CD
	,SEIKYUSAKI_CD
	,SOKO_CD
	,AZUKE_AZUKARI_IDO_SOKO_CD
	,SHUKKA_YOTEI_DATE
	,SHITEI_NOHIN_DATE
	,SHITEI_NOHIN_JIKOKU
	,HAISOU_KBN
	,KESSAI_HOHO
	,HDR_GEDAIMACHI_FLG
	,SAMPLE_SHUKKA_FLG
	,HIKIATE_CHOSEI_FUYO_FLG
	,HDR_SEIKYU_KIJUN_DATE
	,TOKUISAKI_DENPYO_NO
	,TOKUISAKI_HACCHU_NO
	,BUNRUI_CD
	,URIBA_NM
	,TANTOSHA_NM
	,NAISEN_NO
	,TANTOSHA_CD
	,TANTO_BUSHO_CD
	,NOHIN_KBN
	,RYUTU_KAKOU_KBN
	,BIKO
	,JUCHU_COMMENT
	,SOKO_COMMENT
	,PROJECT_CD
	,HANBAI_AREA_CD
	,YOYAKU_KAIHO_KIGEN
	,HINMOKU					
	,LOT_NUM					
	,BARA_NUM				
	,SUITEI_KAKUTEI_KBN		
	,KAKERITU				
	,HIKIATE_STATE			
	,DTL_GEDAIMACHI_FLG		
	,DTL_SOKO_CD				
	,TEKIYO					
	,DTL_SHUKKASAKI_CD		
	,DTL_SHUKKA_YOTEI_DATE	
	,DTL_SHITEI_NOHIN_DATE	
	,DTL_SEIKYU_KIJUN_DATE	
	)
	SELECT TMP_ID
		   ,ROW_NUMBER() OVER(ORDER BY TMP_ID)
		   ,DENPYO_NO
		   ,NULL		--����NO
		   ,NULL		--�q�Ɉړ�NO
		   ,JUCHU_KBN
		   ,JUCHU_DATE
		   ,SHUKKO_KBN
		   ,TOKUISAKI_CD
		   ,SHUKKASAKI_CD
		   ,SEIKYUSAKI_CD
		   ,SOKO_CD
		   ,AZUKE_AZUKARI_IDO_SOKO_CD
		   ,SHUKKA_YOTEI_DATE
		   ,SHITEI_NOHIN_DATE
		   ,SHITEI_NOHIN_JIKOKU
		   ,HAISOU_KBN
		   ,KESSAI_HOHO
		   ,HDR_GEDAIMACHI_FLG
		   ,SAMPLE_SHUKKA_FLG
		   ,HIKIATE_CHOSEI_FUYO_FLG
		   ,HDR_SEIKYU_KIJUN_DATE
		   ,TOKUISAKI_DENPYO_NO
		   ,TOKUISAKI_HACCHU_NO
		   ,BUNRUI_CD
		   ,URIBA_NM
		   ,TANTOSHA_NM
		   ,NAISEN_NO
		   ,TANTOSHA_CD
		   ,TANTO_BUSHO_CD
		   ,NOHIN_KBN
		   ,RYUTU_KAKOU_KBN
		   ,BIKO
		   ,JUCHU_COMMENT
		   ,SOKO_COMMENT
		   ,PROJECT_CD
		   ,HANBAI_AREA_CD
		   ,YOYAKU_KAIHO_KIGEN
		   ,HINMOKU					
		   ,LOT_NUM					
		   ,BARA_NUM				
		   ,SUITEI_KAKUTEI_KBN		
		   ,KAKERITU				
		   ,HIKIATE_STATE			
		   ,DTL_GEDAIMACHI_FLG		
		   ,DTL_SOKO_CD				
		   ,TEKIYO					
		   ,DTL_SHUKKASAKI_CD		
		   ,DTL_SHUKKA_YOTEI_DATE	
		   ,DTL_SHITEI_NOHIN_DATE	
		   ,DTL_SEIKYU_KIJUN_DATE	
	FROM #tmp
	GROUP BY TMP_ID
			,DENPYO_NO
			,JUCHU_KBN
			,JUCHU_DATE
			,SHUKKO_KBN
			,TOKUISAKI_CD
			,SHUKKASAKI_CD
			,SEIKYUSAKI_CD
			,SOKO_CD
			,AZUKE_AZUKARI_IDO_SOKO_CD
			,SHUKKA_YOTEI_DATE
			,SHITEI_NOHIN_DATE
			,SHITEI_NOHIN_JIKOKU
			,HAISOU_KBN
			,KESSAI_HOHO
			,HDR_GEDAIMACHI_FLG
			,SAMPLE_SHUKKA_FLG
			,HIKIATE_CHOSEI_FUYO_FLG
			,HDR_SEIKYU_KIJUN_DATE
			,TOKUISAKI_DENPYO_NO
			,TOKUISAKI_HACCHU_NO
			,BUNRUI_CD
			,URIBA_NM
			,TANTOSHA_NM
			,NAISEN_NO
			,TANTOSHA_CD
			,TANTO_BUSHO_CD
			,NOHIN_KBN
			,RYUTU_KAKOU_KBN
			,BIKO
			,JUCHU_COMMENT
			,SOKO_COMMENT
			,PROJECT_CD
			,HANBAI_AREA_CD
			,YOYAKU_KAIHO_KIGEN
			,HINMOKU					
			,LOT_NUM					
			,BARA_NUM				
			,SUITEI_KAKUTEI_KBN		
			,KAKERITU				
			,HIKIATE_STATE			
			,DTL_GEDAIMACHI_FLG		
			,DTL_SOKO_CD				
			,TEKIYO					
			,DTL_SHUKKASAKI_CD		
			,DTL_SHUKKA_YOTEI_DATE	
			,DTL_SHITEI_NOHIN_DATE	
			,DTL_SEIKYU_KIJUN_DATE	
	--#tmpHdr��GROUP_KEY��#tmp��GROUP_KEY�ɐݒ�
	UPDATE #tmp
	SET GROUP_KEY = #tmpHdr.GROUP_KEY
	FROM #tmpHdr
	WHERE #tmp.TMP_ID = #tmpHdr.TMP_ID
	AND ISNULL(#tmp.DENPYO_NO, '') = ISNULL(#tmpHdr.DENPYO_NO, '')
	AND ISNULL(#tmp.JUCHU_KBN, '') = ISNULL(#tmpHdr.JUCHU_KBN, '')
	AND ISNULL(#tmp.JUCHU_DATE, '') = ISNULL(#tmpHdr.JUCHU_DATE, '')
	AND ISNULL(#tmp.SHUKKO_KBN, '') = ISNULL(#tmpHdr.SHUKKO_KBN, '')
	AND ISNULL(#tmp.TOKUISAKI_CD, '') = ISNULL(#tmpHdr.TOKUISAKI_CD, '')
	AND ISNULL(#tmp.SHUKKASAKI_CD, '') = ISNULL(#tmpHdr.SHUKKASAKI_CD, '')
	AND ISNULL(#tmp.SEIKYUSAKI_CD, '') = ISNULL(#tmpHdr.SEIKYUSAKI_CD, '')
	AND ISNULL(#tmp.SOKO_CD, '') = ISNULL(#tmpHdr.SOKO_CD, '')
	AND ISNULL(#tmp.AZUKE_AZUKARI_IDO_SOKO_CD, '') = ISNULL(#tmpHdr.AZUKE_AZUKARI_IDO_SOKO_CD, '')
	AND ISNULL(#tmp.SHUKKA_YOTEI_DATE, '') = ISNULL(#tmpHdr.SHUKKA_YOTEI_DATE, '')
	AND ISNULL(#tmp.SHITEI_NOHIN_DATE, '') = ISNULL(#tmpHdr.SHITEI_NOHIN_DATE, '')
	AND ISNULL(#tmp.SHITEI_NOHIN_JIKOKU, '') = ISNULL(#tmpHdr.SHITEI_NOHIN_JIKOKU, '')
	AND ISNULL(#tmp.HAISOU_KBN, '') = ISNULL(#tmpHdr.HAISOU_KBN, '')
	AND ISNULL(#tmp.KESSAI_HOHO, '') = ISNULL(#tmpHdr.KESSAI_HOHO, '')
	AND ISNULL(#tmp.HDR_GEDAIMACHI_FLG, '') = ISNULL(#tmpHdr.HDR_GEDAIMACHI_FLG, '')
	AND ISNULL(#tmp.SAMPLE_SHUKKA_FLG, '') = ISNULL(#tmpHdr.SAMPLE_SHUKKA_FLG, '')
	AND ISNULL(#tmp.HIKIATE_CHOSEI_FUYO_FLG, '') = ISNULL(#tmpHdr.HIKIATE_CHOSEI_FUYO_FLG, '')
	AND ISNULL(#tmp.HDR_SEIKYU_KIJUN_DATE, '') = ISNULL(#tmpHdr.HDR_SEIKYU_KIJUN_DATE, '')
	AND ISNULL(#tmp.TOKUISAKI_DENPYO_NO, '') = ISNULL(#tmpHdr.TOKUISAKI_DENPYO_NO, '')
	AND ISNULL(#tmp.TOKUISAKI_HACCHU_NO, '') = ISNULL(#tmpHdr.TOKUISAKI_HACCHU_NO, '')
	AND ISNULL(#tmp.BUNRUI_CD, '') = ISNULL(#tmpHdr.BUNRUI_CD, '')
	AND ISNULL(#tmp.URIBA_NM, '') = ISNULL(#tmpHdr.URIBA_NM, '')
	AND ISNULL(#tmp.TANTOSHA_NM, '') = ISNULL(#tmpHdr.TANTOSHA_NM, '')
	AND ISNULL(#tmp.NAISEN_NO, '') = ISNULL(#tmpHdr.NAISEN_NO, '')
	AND ISNULL(#tmp.TANTOSHA_CD, '') = ISNULL(#tmpHdr.TANTOSHA_CD, '')
	AND ISNULL(#tmp.TANTO_BUSHO_CD, '') = ISNULL(#tmpHdr.TANTO_BUSHO_CD, '')
	AND ISNULL(#tmp.NOHIN_KBN, '') = ISNULL(#tmpHdr.NOHIN_KBN, '')
	AND ISNULL(#tmp.RYUTU_KAKOU_KBN, '') = ISNULL(#tmpHdr.RYUTU_KAKOU_KBN, '')
	AND ISNULL(#tmp.BIKO, '') = ISNULL(#tmpHdr.BIKO, '')
	AND ISNULL(#tmp.JUCHU_COMMENT, '') = ISNULL(#tmpHdr.JUCHU_COMMENT, '')
	AND ISNULL(#tmp.SOKO_COMMENT, '') = ISNULL(#tmpHdr.SOKO_COMMENT, '')
	AND ISNULL(#tmp.PROJECT_CD, '') = ISNULL(#tmpHdr.PROJECT_CD, '')
	AND ISNULL(#tmp.HANBAI_AREA_CD, '') = ISNULL(#tmpHdr.HANBAI_AREA_CD, '')
	AND ISNULL(#tmp.YOYAKU_KAIHO_KIGEN, '') = ISNULL(#tmpHdr.YOYAKU_KAIHO_KIGEN, '')
	AND ISNULL(#tmp.HINMOKU, '') = ISNULL(#tmpHdr.HINMOKU, '')
	AND ISNULL(#tmp.LOT_NUM, '') = ISNULL(#tmpHdr.LOT_NUM, '')
	AND ISNULL(#tmp.BARA_NUM, '') = ISNULL(#tmpHdr.BARA_NUM, '')
	AND ISNULL(#tmp.SUITEI_KAKUTEI_KBN, '') = ISNULL(#tmpHdr.SUITEI_KAKUTEI_KBN, '')
	AND ISNULL(#tmp.KAKERITU, '') = ISNULL(#tmpHdr.KAKERITU, '')
	AND ISNULL(#tmp.HIKIATE_STATE, '') = ISNULL(#tmpHdr.HIKIATE_STATE, '')
	AND ISNULL(#tmp.DTL_GEDAIMACHI_FLG, '') = ISNULL(#tmpHdr.DTL_GEDAIMACHI_FLG, '')
	AND ISNULL(#tmp.DTL_SOKO_CD, '') = ISNULL(#tmpHdr.DTL_SOKO_CD, '')
	AND ISNULL(#tmp.TEKIYO, '') = ISNULL(#tmpHdr.TEKIYO, '')
	AND ISNULL(#tmp.DTL_SHUKKASAKI_CD, '') = ISNULL(#tmpHdr.DTL_SHUKKASAKI_CD, '')
	AND ISNULL(#tmp.DTL_SHUKKA_YOTEI_DATE, '') = ISNULL(#tmpHdr.DTL_SHUKKA_YOTEI_DATE, '')
	AND ISNULL(#tmp.DTL_SHITEI_NOHIN_DATE, '') = ISNULL(#tmpHdr.DTL_SHITEI_NOHIN_DATE, '')
	AND ISNULL(#tmp.DTL_SEIKYU_KIJUN_DATE, '') = ISNULL(#tmpHdr.DTL_SEIKYU_KIJUN_DATE, '')	

	--��GROUP_KEY������̂��̂���̓`�[�̒P��
	/*===============================���R�[�h��`�[�P�ʂɓZ�߂�END===============================*/

	/*===============================�`�[�P�ʂ̃G���[�`�F�b�NSTART===============================*/
	/**********************************************
    *���c�Ȃ������`�F�b�NSTART
    **********************************************/
	--�@�o�ח\���(����)�`�F�b�N
	--�o�ח\������قȂ�ꍇ�G���[
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_JUCHU_ZAM_KANRI_DATE + @FLD_NM_DTL_SHUKKA_YOTEI_DATE
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.JUCHU_KBN IN ('01', '03')
    AND EXISTS (SELECT *
				FROM (SELECT T.LINE_NO
							,T.GROUP_KEY
							,T.DTL_SHUKKA_YOTEI_DATE
				      FROM #tmp T
					  INNER JOIN BC_MST_TOKUISAKI_EX TOKUI
						ON T.TOKUISAKI_CD = TOKUI.TOKUISAKI_CD
						AND TOKUI.JUCHU_ZAN_KANRI_FLG = 0
					  WHERE T.ERROR_MSG IS NULL
					  AND TOKUI.KAISHA_CD = @KAISHA_CD
					  ) AS tmp2
                WHERE tmp2.GROUP_KEY = #tmp.GROUP_KEY
                AND tmp2.DTL_SHUKKA_YOTEI_DATE <> #tmp.DTL_SHUKKA_YOTEI_DATE
                AND tmp2.LINE_NO < #tmp.LINE_NO
			   )

	--�A�w��[�i��(����)�`�F�b�N
	--�w��[�i��(����)���قȂ�ꍇ�G���[
	--�w��[�i���͕K�{���ڂł͂Ȃ��̂ŁA�`�F�b�N��null�ϊ����{
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_JUCHU_ZAM_KANRI_DATE + @FLD_NM_SHITEI_NOHIN_DATE
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.JUCHU_KBN IN ('01', '03')
    AND EXISTS (SELECT *
				FROM (SELECT T.LINE_NO
							,T.GROUP_KEY
							,T.DTL_SHITEI_NOHIN_DATE
				      FROM #tmp T
					  INNER JOIN BC_MST_TOKUISAKI_EX TOKUI
						ON T.TOKUISAKI_CD = TOKUI.TOKUISAKI_CD
						AND TOKUI.JUCHU_ZAN_KANRI_FLG = 0
					  WHERE T.ERROR_MSG IS NULL
					  AND TOKUI.KAISHA_CD = @KAISHA_CD
					 ) AS tmp2
                WHERE tmp2.GROUP_KEY = #tmp.GROUP_KEY
                AND  ISNULL(tmp2.DTL_SHITEI_NOHIN_DATE, '') <> ISNULL(#tmp.DTL_SHITEI_NOHIN_DATE, '')
                AND tmp2.LINE_NO < #tmp.LINE_NO
			   )

	--�B�����(����)�`�F�b�N
	--�������(����)���قȂ�ꍇ�G���[
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_JUCHU_ZAM_KANRI_DATE + @FLD_NM_SEIKYU_KIJUN_DATE
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.JUCHU_KBN IN ('01', '03')
    AND EXISTS (SELECT *
				FROM (SELECT T.LINE_NO
							,T.GROUP_KEY
							,T.DTL_SEIKYU_KIJUN_DATE
				      FROM #tmp T
					  INNER JOIN BC_MST_TOKUISAKI_EX TOKUI
						ON T.TOKUISAKI_CD = TOKUI.TOKUISAKI_CD
						AND TOKUI.JUCHU_ZAN_KANRI_FLG = 0
					  WHERE T.ERROR_MSG IS NULL
					  AND TOKUI.KAISHA_CD = @KAISHA_CD
					 ) AS tmp2
                WHERE tmp2.GROUP_KEY = #tmp.GROUP_KEY
                AND  tmp2.DTL_SEIKYU_KIJUN_DATE <> #tmp.DTL_SEIKYU_KIJUN_DATE
                AND tmp2.LINE_NO < #tmp.LINE_NO
			   )

	--�C�o�א�(����)���قȂ�ꍇ�G���[
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_JUCHU_ZAM_KANRI_SHUKKASAKI
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.JUCHU_KBN IN ('01', '03')
    AND EXISTS (SELECT *
				FROM (SELECT T.LINE_NO
							,T.GROUP_KEY
							,T.DTL_SHUKKASAKI_CD
				      FROM #tmp T
					  INNER JOIN BC_MST_TOKUISAKI_EX TOKUI
						ON T.TOKUISAKI_CD = TOKUI.TOKUISAKI_CD
						AND TOKUI.JUCHU_ZAN_KANRI_FLG = 0
					  WHERE T.ERROR_MSG IS NULL
					  AND TOKUI.KAISHA_CD = @KAISHA_CD
					 ) AS tmp2
                WHERE tmp2.GROUP_KEY = #tmp.GROUP_KEY
                AND  tmp2.DTL_SHUKKASAKI_CD <> #tmp.DTL_SHUKKASAKI_CD
                AND tmp2.LINE_NO < #tmp.LINE_NO
			   )
	/**********************************************
    *���c�Ȃ������`�F�b�NEND
    **********************************************/

	/**********************************************
    *�o�א�E�o�ח\����Ɛ�������̃`�F�b�NSTART
    **********************************************/
	--�o�א�E�o�ח\���������̏ꍇ�A�������������ł��邱��
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_SEIKYUKIJUN_DATE
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.JUCHU_KBN = '01'
    AND EXISTS (SELECT *
				FROM #tmp tmp2
                WHERE tmp2.GROUP_KEY = #tmp.GROUP_KEY
				AND tmp2.ERROR_MSG IS NULL
                AND tmp2.DTL_SHUKKASAKI_CD = #tmp.DTL_SHUKKASAKI_CD
				AND tmp2.DTL_SHUKKA_YOTEI_DATE = #tmp.DTL_SHUKKA_YOTEI_DATE
				AND tmp2.DTL_SEIKYU_KIJUN_DATE <> #tmp.DTL_SEIKYU_KIJUN_DATE
                AND tmp2.LINE_NO < #tmp.LINE_NO
			   )
	/**********************************************
    *�o�א�E�o�ח\����Ɛ�������̃`�F�b�NSTART
    **********************************************/
	--���ׂ̓o�^�����`�F�b�N(1�`�[�ɑ΂�999���܂�)
	UPDATE #tmp
	SET #tmp.ERROR_MSG = @ERR_MSG_DTL_COUNT_OVER + '�F' 
						+ '�s�ԍ�' + CONVERT(NVARCHAR, tmpCnt.MIN_LINE) + '�`' + '�s�ԍ�' + CONVERT(NVARCHAR, tmpCnt.MAX_LINE)
	FROM #tmp
	INNER JOIN (SELECT #tmp.GROUP_KEY
					  ,MIN(#tmp.LINE_NO) AS MIN_LINE
					  ,MAX(#tmp.LINE_NO) AS MAX_LINE
	            FROM #tmp
			    GROUP BY #tmp.GROUP_KEY
			    HAVING COUNT(*) > 999
			  ) tmpCnt
		ON #tmp.GROUP_KEY = tmpCnt.GROUP_KEY
		AND #tmp.LINE_NO = tmpCnt.MIN_LINE
	WHERE #tmp.ERROR_MSG IS NULL

	/*===============================�`�[�P�ʂ̃G���[�`�F�b�NEND===============================*/

	/*===============================���ʈ���START===============================*/
	CREATE TABLE #tmpHikiate
    (KBN					INT
	,TOKUISAKI_CD			NVARCHAR(15)
	,PARENT_TOKUISAKI_CD	NVARCHAR(15)
	,SOKO_CD				NVARCHAR(15)
	,HINMOKU_SEQ			DECIMAL(10)
	,YOYAKU_JUCHU_NO		NVARCHAR(15)
	,YOYAKU_JUCHU_ENO		DECIMAL(3)
	,SHUKKA_YOTEI_DATE		DATETIME
	,NYUKA_YOTEI_NO			NVARCHAR(16)
	,NYUKA_YOTEI_DATE		DATETIME
	,ZAIKO_SEQ				DECIMAL(10)
	,ZAIKO_TOKUISAKI		NVARCHAR(15)
	,SHUKKA_KANO_DATE		DATETIME
	,SURYO					DECIMAL(13, 3)
	)

	--���ʈ����p�̕ϐ��ݒ�
	DECLARE @LINE_NO			DECIMAL(6)
		   ,@JUCHU_KBN			NVARCHAR(2)
		   ,@TOKUISAKI_CD		NVARCHAR(15)
		   ,@SOKO_CD			NVARCHAR(15)
		   ,@HINMOKU_SEQ		DECIMAL(10)
		   ,@SHUKKA_YOTEI_DATE	DATETIME
		   ,@YOYAKU_DENPYO_NO	NVARCHAR(15)
		   ,@YOYAKU_DENPYO_ENO	DECIMAL(3)
		   ,@SHUKKO_KBN			NVARCHAR(2)

	/*********************************************************************************
	*�����\���̏ڍ׏����擾
	*�o�ח\��͐��ʂ�������ꍇ�ɍl������̂ŁA�����\���ڍ׏����擾����ۂ͍l�����Ȃ�
	**********************************************************************************/
	DECLARE HIKIATE_CUR CURSOR FOR
	SELECT DISTINCT 
		   TOKUISAKI_CD
		  ,DTL_SOKO_CD
		  ,HINMOKU_SEQ
		  ,YOYAKU_DENPYO_NO
		  ,YOYAKU_DENPYO_ENO
	FROM #tmp
	
	OPEN HIKIATE_CUR
	FETCH NEXT FROM HIKIATE_CUR
	INTO @TOKUISAKI_CD
		,@SOKO_CD
		,@HINMOKU_SEQ
		,@YOYAKU_DENPYO_NO
		,@YOYAKU_DENPYO_ENO
	WHILE @@FETCH_STATUS = 0
	BEGIN
		
		INSERT INTO #tmpHikiate
		EXEC GetHikiateKanoSuryoDetail_Ex
		@KAISHA_CD
		,@TOKUISAKI_CD
		,@SOKO_CD
		,@HINMOKU_SEQ
		,NULL
		,@YOYAKU_DENPYO_NO
		,@YOYAKU_DENPYO_ENO

		FETCH NEXT FROM HIKIATE_CUR
		INTO @TOKUISAKI_CD
			,@SOKO_CD
			,@HINMOKU_SEQ	
			,@YOYAKU_DENPYO_NO
			,@YOYAKU_DENPYO_ENO	
	END

	CLOSE HIKIATE_CUR
	DEALLOCATE HIKIATE_CUR

	--�ϐ��̏�����
	SET @TOKUISAKI_CD = NULL
	SET @SOKO_CD = NULL
	SET @HINMOKU_SEQ = NULL
	
	/*************************************************
	*������Ԃ��u���v�u�ꊇ�����v�̐��ʈ���
	*����o�^�̂��߁A�o�ח\��͍쐬���Ȃ�
	*�����\���͍l�����Ȃ��B�󒍐���=�������Ƃ���B
	**************************************************/
	UPDATE #tmp
	SET SURYO = CASE WHEN ERROR_MSG IS NULL
							THEN (CONVERT(DECIMAL(13, 3),ISNULL(LOT_NUM, '0')) * ISNULL(HIN.STD_IRISU, 0)) + CONVERT(DECIMAL(13, 3),ISNULL(BARA_NUM, '0'))
					 ELSE 0--�G���[�s��0�Ƃ���
				END
	FROM #tmp
	LEFT JOIN BC_MST_HINMOKU_KANRI HINKAN
		ON HINKAN.HINMOKU_SEQ = #tmp.HINMOKU_SEQ
	LEFT JOIN BC_MST_HINMOKU HIN
		ON HIN.KAISHA_CD = HINKAN.KAISHA_CD
		AND HIN.HINMOKU_CD = HINKAN.HINMOKU_CD
	WHERE HIKIATE_STATE IN ('01', '03') 
	AND HINKAN.KAISHA_CD = @KAISHA_CD

	/************************************************************************************
	*������Ԃ��u�����v�̐��ʈ���
	*�������ȉ��̍ő�̈����\�������������{����B�����Ώۂ����݂��Ȃ��ꍇ�A0��ݒ�
	*�G���[���s�ɑ΂��Ă݈̂������������{
	*�����������ň������s���A�s�������ꍇ�́A���b�g�P�ʂŊm�ۂł��鐔�܂ň����B
	*�݌ɊǗ��O�i�͈������𒍕����Ƃ���
	*************************************************************************************/
	--�o�ח\��쐬�pTBL
	CREATE TABLE #tmpShukkaYotei
    (LINE_NO				DECIMAL(6)
	,SURYO					DECIMAL(13, 3)
	,HINMOKU_SEQ			DECIMAL(10)
	,ZAIKO_SEQ				DECIMAL(10)
	,NYUKA_YOTEI_NO			NVARCHAR(16)
	,YOYAKU_JUCHU_NO		NVARCHAR(15)
	,YOYAKU_JUCHU_ENO		DECIMAL(3)
	)

	DECLARE @cnt int

	--�G���[�s�̎擾
	SELECT
		@cnt = count(*)
	FROM #tmp
	WHERE ERROR_MSG IS NOT NULL

	--�G���[�s����ł�����΁A���������Ɨ^�M�`�F�b�N�͍s��Ȃ��B
	IF(@cnt = 0)
	BEGIN

	DECLARE @SURYO					DECIMAL(13,3)	--�󒍐�
	DECLARE @IS_ZAIKO_KANRI			TINYINT			--�݌ɊǗ��t���O

	DECLARE @CHUMON_SURYO			DECIMAL(13,3)	--������
	DECLARE @IRI_SURYO				DECIMAL(13,3)	--���萔
	DECLARE @MAX_HIKIATE_SURYO		DECIMAL(13,3)	--�ő�����\��

	--���������p�̕ϐ�
	DECLARE @HIKIATE_KBN			INT				--�����敪
	DECLARE @HIKIATE_SURYO			DECIMAL(13,3)	--�����\��
	DECLARE @ZAIKO_SEQ				DECIMAL(10)		--�݌�SEQ
	DECLARE @NYUKA_YOTEI_NO			NVARCHAR(16)	--���ח\��NO
	DECLARE @YOYAKU_JUCHU_NO		NVARCHAR(12)	--�\��`�[NO
	DECLARE @YOYAKU_JUCHU_ENO		DECIMAL(3)		--�\��}��
	DECLARE @HIKIATE_ZAN_SURYO		DECIMAL(13,3)	--�����c��

	DECLARE tmp_CUR CURSOR FOR
	SELECT LINE_NO
		  ,JUCHU_KBN
		  ,TOKUISAKI_CD
		  ,#tmp.HINMOKU_SEQ
		  ,DTL_SOKO_CD
		  ,CONVERT(DATETIME, SHUKKA_YOTEI_DATE)
		  ,YOYAKU_DENPYO_NO
		  ,CONVERT(DECIMAL, YOYAKU_DENPYO_ENO)
		  ,SHUKKO_KBN
	FROM #tmp
	WHERE HIKIATE_STATE = '02'	--�����݈̂����\�����l��
	  AND ERROR_MSG IS NULL
	ORDER BY JUCHU_DATE
			,DTL_SHUKKA_YOTEI_DATE
			,JUCHU_KBN
			,LINE_NO
			
	OPEN tmp_CUR
	FETCH NEXT FROM tmp_CUR
	INTO @LINE_NO
		,@JUCHU_KBN
		,@TOKUISAKI_CD
		,@HINMOKU_SEQ
		,@SOKO_CD
		,@SHUKKA_YOTEI_DATE
		,@YOYAKU_DENPYO_NO
		,@YOYAKU_DENPYO_ENO
		,@SHUKKO_KBN
	WHILE @@FETCH_STATUS = 0
	BEGIN
	
		SELECT @IS_ZAIKO_KANRI = HIN.ZAIKO_KANRI_FLG
		FROM BC_MST_HINMOKU_KANRI HINKAN
		LEFT JOIN BC_MST_HINMOKU HIN
			ON HINKAN.KAISHA_CD =HIN.KAISHA_CD
			AND HINKAN.HINMOKU_CD = HIN.HINMOKU_CD
		WHERE HINKAN.KAISHA_CD = @KAISHA_CD
		AND HINKAN.HINMOKU_SEQ = @HINMOKU_SEQ

		--���������擾
		SELECT @CHUMON_SURYO = (CONVERT(DECIMAL(13, 3),ISNULL(#tmp.LOT_NUM, '0')) * ISNULL(HIN.STD_IRISU, 0)) + CONVERT(DECIMAL(13, 3),ISNULL(BARA_NUM, '0')),
				@IRI_SURYO = HIN.STD_IRISU
		FROM #tmp
		LEFT JOIN BC_MST_HINMOKU_KANRI HINKAN
			ON HINKAN.HINMOKU_SEQ = #tmp.HINMOKU_SEQ
		LEFT JOIN BC_MST_HINMOKU HIN
			ON HIN.KAISHA_CD = HINKAN.KAISHA_CD
			AND HIN.HINMOKU_CD = HINKAN.HINMOKU_CD
		WHERE LINE_NO = @LINE_NO
		AND #tmp.HINMOKU_SEQ = @HINMOKU_SEQ
		
		IF (@IS_ZAIKO_KANRI = 1)
		BEGIN
			--�݌ɊǗ��i
			--������(�������ȉ��̍ő�܂ň���)�����߂�

			--�ő�����\�����擾
			SELECT @MAX_HIKIATE_SURYO = SUM(ISNULL(HIKIATE.SURYO, 0))
			FROM #tmpHikiate HIKIATE
			WHERE SOKO_CD = @SOKO_CD
			AND HINMOKU_SEQ = @HINMOKU_SEQ
			AND TOKUISAKI_CD = @TOKUISAKI_CD
			--�a����o��04�A�a������07�͍݌ɂ̓��Ӑ悪��v���邱��
			--���͍݌ɂ̓��Ӑ�͏����ɂ��Ă����Ȃ�
			AND ((@SHUKKO_KBN IN ('04', '07') AND ZAIKO_TOKUISAKI = @TOKUISAKI_CD)
					OR (@SHUKKO_KBN NOT IN ('04', '07') AND ZAIKO_TOKUISAKI IS NULL)
				)
			AND ((KBN = 1 AND(DATEDIFF(dd, HIKIATE.SHUKKA_YOTEI_DATE, @SHUKKA_YOTEI_DATE) >= 0))		--�\��
					OR (KBN = 2 AND(DATEDIFF(dd, HIKIATE.SHUKKA_YOTEI_DATE, @SHUKKA_YOTEI_DATE) >= 0))	--�e�\��
					 OR (KBN = 3 AND(DATEDIFF(dd, HIKIATE.SHUKKA_KANO_DATE, @SHUKKA_YOTEI_DATE) <= 0))	--�݌�
					 OR (KBN = 5 AND(DATEDIFF(dd, HIKIATE.SHUKKA_YOTEI_DATE, @SHUKKA_YOTEI_DATE) >= 0))	--�\��S��
				)
			--�\��݌ɂ���̈����̂�
			AND ((@JUCHU_KBN = '01' AND @YOYAKU_DENPYO_NO IS NULL AND KBN IN (1, 2, 3))--�\�񖢎w��
				 OR
				 (@JUCHU_KBN = '01' AND @YOYAKU_DENPYO_NO IS NOT NULL AND KBN = 5)		--�\��w��
				 OR 
				 (@JUCHU_KBN = '02' AND KBN = 3)
				 OR 
				 (@JUCHU_KBN = '03' AND KBN IN (1, 2, 3)) --�ړ��͗\��A�݌ɂ������
				 )
			--�\��`�[�w��̏ꍇ�A�Ώۂ̗\��݈̂�����B���̂Ƃ��A���Ӑ�R�[�h�͖�������
			AND ((@YOYAKU_DENPYO_NO IS NULL AND TOKUISAKI_CD = @TOKUISAKI_CD)
					OR (HIKIATE.YOYAKU_JUCHU_NO = @YOYAKU_DENPYO_NO AND HIKIATE.YOYAKU_JUCHU_ENO = @YOYAKU_DENPYO_ENO))
			--���ʂ����݂�����̂̂�
			AND SURYO > 0

			--�ő�����\���ƒ��������r
			IF(@MAX_HIKIATE_SURYO > @CHUMON_SURYO)
			BEGIN
				--������������ɑ��݂���̂Œ��������Z�b�g			
				SET @SURYO = @CHUMON_SURYO
			END
			ELSE
			BEGIN
				IF @IRI_SURYO IS NULL OR @IRI_SURYO = 0 BEGIN
				SET @CHUMON_SURYO = @MAX_HIKIATE_SURYO
				--�������𖞂����Ȃ��A�����b�g�����Ȃ����ߍő���������Z�b�g
				SET @SURYO = @MAX_HIKIATE_SURYO
				END
				ELSE BEGIN 
				SET @CHUMON_SURYO = @MAX_HIKIATE_SURYO - 1
				--�������𖞂����Ȃ��A�����b�g�P�ʂŊm�ۂł��邽�߁A�ő������-1���Z�b�g
				SET @SURYO = @MAX_HIKIATE_SURYO -1
				END
			END
		
		END
				

		--#tmpShukkaYotei�ɓo�^
		IF (ISNULL(@SURYO, 0) > 0)
		BEGIN
			--�����c���ɐ��ʂ��Z�b�g
			SET @HIKIATE_ZAN_SURYO = @SURYO

			--�󒍐��ɒB����܂ň��������[�v����
			DECLARE hikiateCUR CURSOR FOR
			SELECT KBN
				  ,ISNULL(HIKIATE.SURYO, 0)
				  ,HIKIATE.ZAIKO_SEQ
				  ,HIKIATE.NYUKA_YOTEI_NO
				  ,HIKIATE.YOYAKU_JUCHU_NO
				  ,HIKIATE.YOYAKU_JUCHU_ENO
			FROM #tmpHikiate HIKIATE
			WHERE SOKO_CD = @SOKO_CD
			AND HINMOKU_SEQ = @HINMOKU_SEQ
			AND TOKUISAKI_CD = @TOKUISAKI_CD
			--�a����o��04�A�a������07�͍݌ɂ̓��Ӑ悪��v���邱��
			--���͍݌ɂ̓��Ӑ�͏����ɂ��Ă����Ȃ�
			AND ((@SHUKKO_KBN IN ('04', '07') AND ZAIKO_TOKUISAKI = @TOKUISAKI_CD)
					OR (@SHUKKO_KBN NOT IN ('04', '07') AND ZAIKO_TOKUISAKI IS NULL)
				)
			AND ((KBN = 1 AND(DATEDIFF(dd, HIKIATE.SHUKKA_YOTEI_DATE, @SHUKKA_YOTEI_DATE) >= 0))
					OR (KBN = 2 AND(DATEDIFF(dd, HIKIATE.SHUKKA_YOTEI_DATE, @SHUKKA_YOTEI_DATE) >= 0))
					 OR (KBN = 3 AND(DATEDIFF(dd, HIKIATE.SHUKKA_KANO_DATE, @SHUKKA_YOTEI_DATE) <= 0))
					 OR (KBN = 5 AND(DATEDIFF(dd, HIKIATE.SHUKKA_YOTEI_DATE, @SHUKKA_YOTEI_DATE) >= 0))
				)
			AND ((@JUCHU_KBN = '01' AND @YOYAKU_DENPYO_NO IS NULL AND KBN IN (1, 2, 3))
				 OR
				 (@JUCHU_KBN = '01' AND @YOYAKU_DENPYO_NO IS NOT NULL AND KBN = 5)
				 OR 
				 (@JUCHU_KBN = '02' AND KBN = 3)
				 OR 
				 (@JUCHU_KBN = '03' AND KBN IN (1, 2, 3)) --�ړ��͗\��A�݌ɂ������
				 )
			AND ((@YOYAKU_DENPYO_NO IS NULL AND TOKUISAKI_CD = @TOKUISAKI_CD)
					OR (HIKIATE.KBN = 5 AND HIKIATE.YOYAKU_JUCHU_NO = @YOYAKU_DENPYO_NO AND HIKIATE.YOYAKU_JUCHU_ENO = @YOYAKU_DENPYO_ENO))
			AND SURYO > 0
			ORDER BY KBN				--����(�\�񁄐e�\��>�݌ɂ̏�)
					,SHUKKA_YOTEI_DATE	--����

			OPEN hikiateCUR
			FETCH NEXT FROM hikiateCUR
			INTO @HIKIATE_KBN 
				,@HIKIATE_SURYO
				,@ZAIKO_SEQ
				,@NYUKA_YOTEI_NO
				,@YOYAKU_JUCHU_NO
				,@YOYAKU_JUCHU_ENO
			--���[�v�\�������c�������݂���ԌJ��Ԃ�
			WHILE (@@FETCH_STATUS = 0 AND @HIKIATE_ZAN_SURYO > 0)
			BEGIN
				IF(@HIKIATE_SURYO >= @HIKIATE_ZAN_SURYO)
				BEGIN
					--�����\���������c�����傫��
					--�����\���ʂɎc����ݒ�
					SET @HIKIATE_SURYO = @HIKIATE_ZAN_SURYO
					--�����c����0�ݒ�
					SET @HIKIATE_ZAN_SURYO = 0
				END
				ELSE
				BEGIN
					--�����c�����������������
					SET @HIKIATE_ZAN_SURYO = @HIKIATE_ZAN_SURYO - @HIKIATE_SURYO
				END

				--#tmpHikiate�̐��ʂ��X�V����
				--���ʂ��������������
				--�e���Ӑ�̗\��������l�����A���Ӑ�͏����Ɋ܂߂Ȃ�
				UPDATE #tmpHikiate
				SET SURYO = SURYO - @HIKIATE_SURYO
				FROM #tmpHikiate hikiate
				WHERE (@ZAIKO_SEQ IS NULL OR hikiate.ZAIKO_SEQ = @ZAIKO_SEQ)
				  AND (@NYUKA_YOTEI_NO IS NULL OR hikiate.NYUKA_YOTEI_NO = @NYUKA_YOTEI_NO)
				  AND (@YOYAKU_JUCHU_NO IS NULL OR hikiate.YOYAKU_JUCHU_NO = @YOYAKU_JUCHU_NO)
				  AND (@YOYAKU_JUCHU_ENO IS NULL OR hikiate.YOYAKU_JUCHU_ENO = @YOYAKU_JUCHU_ENO)

				--�o�ח\��쐬�p�̈ꎞ�e�[�u���Ɉ��������i�[
				INSERT INTO #tmpShukkaYotei
				(LINE_NO
				,SURYO
				,HINMOKU_SEQ
				,ZAIKO_SEQ
				,NYUKA_YOTEI_NO
				,YOYAKU_JUCHU_NO
				,YOYAKU_JUCHU_ENO
				)
				SELECT @LINE_NO
					  ,@HIKIATE_SURYO
					  ,@HINMOKU_SEQ
					  ,@ZAIKO_SEQ
					  ,@NYUKA_YOTEI_NO
					  ,@YOYAKU_JUCHU_NO
					  ,@YOYAKU_JUCHU_ENO

				--�����敪��ݒ肷��
				--01:�\�����
				--02:�݁{�\����
				--03:�݌Ɉ���
				--�ŏ����݌Ɉ����̏ꍇ�A�\��͑��݂��Ȃ�
				UPDATE #tmp
				SET HIKIATE_KBN = CASE WHEN (HIKIATE_KBN IS NULL OR HIKIATE_KBN = '')
											THEN CASE @HIKIATE_KBN
													WHEN 1 THEN '01'	--�\��
													WHEN 2 THEN '01'	--�e�\��
													WHEN 3 THEN '03'	--�݌�
													WHEN 5 THEN '01'	--�\��w�����
												  END
									   WHEN HIKIATE_KBN = '01' AND @HIKIATE_KBN = 3
												THEN '02'
								   ELSE HIKIATE_KBN
								  END
				WHERE LINE_NO = @LINE_NO

				--�\������̏ꍇ�A�\��`�[�̐��ʁE���z���X�V����
				IF (@HIKIATE_KBN IN (1,2,5))
				BEGIN
					--�󒍖���
					UPDATE HK_TBL_JUCHU_DTL
					SET SURYO = SURYO - @HIKIATE_SURYO
					   ,KINGAKU = dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, HDR.TOKUISAKI_CD, DTL.TANKA * (DTL.SURYO - @HIKIATE_SURYO), 1, 0)	--���z
					   ,SHOHIZEI=dbo.CO_FUNC_HASU_SHORI((DTL.TANKA * (DTL.SURYO - @HIKIATE_SURYO)) * DTL.TAX_RATE, TORI.JUCHU_SHOHIZEI_HASU_KBN, 0)		--�����
					   ,UPD_TM = SYSDATETIME()
					   ,UPD_PGM_CD = @PGM_CD
					   ,UPD_SHAIN_CD = @USER_ID
					FROM HK_TBL_JUCHU_DTL DTL
					LEFT JOIN HK_TBL_JUCHU_HDR HDR
						ON HDR.KAISHA_CD = DTL.KAISHA_CD
						AND HDR.JUCHU_NO = DTL.JUCHU_NO
					LEFT JOIN BC_MST_TORIHIKISAKI TORI
						ON TORI.KAISHA_CD = HDR.KAISHA_CD
						AND TORI.TORIHIKISAKI_CD = HDR.TOKUISAKI_CD
					WHERE DTL.KAISHA_CD = @KAISHA_CD
					AND DTL.JUCHU_NO = @YOYAKU_JUCHU_NO
					AND DTL.JUCHU_ENO = @YOYAKU_JUCHU_ENO

					--�󒍖��׊O��
					UPDATE HK_TBL_JUCHU_DTL_GAIKA
					SET TUKA_KINGAKU = dbo.CO_FUNC_HASU_SHORI_EX(DTL_GAIKA.TUKA_TANKA * DTL.SURYO ,'01' ,TUKA.DECIMAL_LENGTH)
					   ,UPD_TM = SYSDATETIME()
					   ,UPD_PGM_CD = @PGM_CD
					   ,UPD_SHAIN_CD = @USER_ID
					FROM HK_TBL_JUCHU_DTL_GAIKA DTL_GAIKA
					LEFT JOIN HK_TBL_JUCHU_DTL DTL
						ON DTL.KAISHA_CD = DTL_GAIKA.KAISHA_CD
						AND DTL.JUCHU_NO = DTL_GAIKA.JUCHU_NO
						AND DTL.JUCHU_ENO = DTL_GAIKA.JUCHU_ENO
					LEFT JOIN HK_TBL_JUCHU_HDR_GAIKA HDR_GAIKA
						ON HDR_GAIKA.KAISHA_CD = DTL.KAISHA_CD
						AND HDR_GAIKA.JUCHU_NO = DTL.JUCHU_NO
					LEFT JOIN BC_MST_TUKA TUKA
						ON TUKA.KAISHA_CD = HDR_GAIKA.KAISHA_CD
						AND TUKA.TUKA_CD = HDR_GAIKA.TUKA_CD
						AND TUKA.DEL_FLG = 0
						AND TUKA.MUKOU_FLG = 0
					WHERE DTL_GAIKA.KAISHA_CD = @KAISHA_CD
					AND DTL_GAIKA.JUCHU_NO = @YOYAKU_JUCHU_NO
					AND DTL_GAIKA.JUCHU_ENO = @YOYAKU_JUCHU_ENO

					--�o�ח\��
					UPDATE HK_TBL_SHUKKA_YOTEI
					SET SURYO = SY.SURYO - @HIKIATE_SURYO
					   ,KINGAKU = dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, HDR.TOKUISAKI_CD, DTL.TANKA * (SY.SURYO - @HIKIATE_SURYO), 1, 0)	--���z
					   ,JISSEKI_KINGAKU = dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, HDR.TOKUISAKI_CD, DTL.TANKA * (SY.SURYO - @HIKIATE_SURYO), 1, 0)	--���ы��z
					   ,SHOHIZEI=dbo.CO_FUNC_HASU_SHORI((DTL.TANKA * (SY.SURYO - @HIKIATE_SURYO)) * SY.TAX_RATE, TORI.JUCHU_SHOHIZEI_HASU_KBN, 0)		--�����
					   ,JISSEKI_SHOHIZEI=dbo.CO_FUNC_HASU_SHORI((DTL.TANKA * (SY.SURYO - @HIKIATE_SURYO)) * SY.TAX_RATE, TORI.JUCHU_SHOHIZEI_HASU_KBN, 0)		--���я����
					   ,UPD_TM = SYSDATETIME()
					   ,UPD_PGM_CD = @PGM_CD
					   ,UPD_SHAIN_CD = @USER_ID
					FROM HK_TBL_SHUKKA_YOTEI SY
					LEFT JOIN HK_TBL_JUCHU_DTL DTL
						ON DTL.KAISHA_CD = SY.KAISHA_CD
						AND DTL.JUCHU_NO = SY.JUCHU_NO
						AND DTL.JUCHU_ENO = SY.JUCHU_ENO
					LEFT JOIN HK_TBL_JUCHU_HDR HDR
						ON HDR.KAISHA_CD = DTL.KAISHA_CD
						AND HDR.JUCHU_NO = DTL.JUCHU_NO
					LEFT JOIN BC_MST_TORIHIKISAKI TORI
						ON TORI.KAISHA_CD = HDR.KAISHA_CD
						AND TORI.TORIHIKISAKI_CD = HDR.TOKUISAKI_CD
					WHERE SY.KAISHA_CD = @KAISHA_CD
					AND SY.JUCHU_NO = @YOYAKU_JUCHU_NO
					AND SY.JUCHU_ENO = @YOYAKU_JUCHU_ENO
					AND SY.DEL_FLG = 0

					--�o�ח\��O��
					UPDATE HK_TBL_SHUKKA_YOTEI_GAIKA
					SET TUKA_KINGAKU = dbo.CO_FUNC_HASU_SHORI_EX(DTL_GAIKA.TUKA_TANKA * SY.SURYO ,'01' ,TUKA.DECIMAL_LENGTH)
					   ,JISSEKI_TUKA_KINGAKU = dbo.CO_FUNC_HASU_SHORI_EX(DTL_GAIKA.TUKA_TANKA * SY.SURYO ,'01' ,TUKA.DECIMAL_LENGTH)
					   ,UPD_TM = SYSDATETIME()
					   ,UPD_PGM_CD = @PGM_CD
					   ,UPD_SHAIN_CD = @USER_ID
					FROM HK_TBL_SHUKKA_YOTEI_GAIKA SY_GAIKA
					INNER JOIN HK_TBL_SHUKKA_YOTEI SY
						ON SY.KAISHA_CD = SY_GAIKA.KAISHA_CD
						AND SY.SHUKKA_YOTEI_NO = SY_GAIKA.SHUKKA_YOTEI_NO
					LEFT JOIN HK_TBL_JUCHU_DTL_GAIKA DTL_GAIKA
						ON DTL_GAIKA.KAISHA_CD = SY.KAISHA_CD
						AND DTL_GAIKA.JUCHU_NO = SY.JUCHU_NO
						AND DTL_GAIKA.JUCHU_ENO = SY.JUCHU_ENO
					LEFT JOIN HK_TBL_JUCHU_HDR_GAIKA HDR_GAIKA
						ON HDR_GAIKA.KAISHA_CD = DTL_GAIKA.KAISHA_CD
						AND HDR_GAIKA.JUCHU_NO = DTL_GAIKA.JUCHU_NO
					LEFT JOIN BC_MST_TUKA TUKA
						ON TUKA.KAISHA_CD = HDR_GAIKA.KAISHA_CD
						AND TUKA.TUKA_CD = HDR_GAIKA.TUKA_CD
						AND TUKA.DEL_FLG = 0
						AND TUKA.MUKOU_FLG = 0
					WHERE SY.KAISHA_CD = @KAISHA_CD
					AND SY.JUCHU_NO = @YOYAKU_JUCHU_NO
					AND SY.JUCHU_ENO = @YOYAKU_JUCHU_ENO
					AND SY.DEL_FLG = 0

				END

				FETCH NEXT FROM hikiateCUR
				INTO @HIKIATE_KBN
					,@HIKIATE_SURYO
					,@ZAIKO_SEQ
					,@NYUKA_YOTEI_NO
					,@YOYAKU_JUCHU_NO
					,@YOYAKU_JUCHU_ENO
			END

			CLOSE hikiateCUR
			DEALLOCATE hikiateCUR
		END
		ELSE
		BEGIN
			--�����������݂��Ȃ��A�܂��́A�݌ɊǗ��O�̏ꍇ
			IF (@IS_ZAIKO_KANRI = 1)
			BEGIN
				--�݌ɊǗ��i
				SET @SURYO = 0
			END
			ELSE
			BEGIN
				--�݌ɊǗ��O�i
				SET @SURYO = @CHUMON_SURYO
			END
			
			INSERT INTO #tmpShukkaYotei
			(LINE_NO
			,SURYO
			,HINMOKU_SEQ
			,ZAIKO_SEQ
			,NYUKA_YOTEI_NO
			,YOYAKU_JUCHU_NO
			,YOYAKU_JUCHU_ENO
			)
			SELECT @LINE_NO
				  ,@SURYO
				  ,@HINMOKU_SEQ
				  ,NULL
				  ,NULL
				  ,NULL
				  ,NULL

			--�݌ɊǗ��O�́uNULL�v�A����0�́u�������v
			UPDATE #tmp
			SET HIKIATE_KBN = 
			CASE WHEN @IS_ZAIKO_KANRI = 1 THEN '00'	--������
			ELSE NULL
			END
			WHERE LINE_NO = @LINE_NO
		END
		
		--���ʂ��Z�b�g
		UPDATE #tmp
		SET SURYO = @SURYO
		WHERE LINE_NO = @LINE_NO

		FETCH NEXT FROM tmp_CUR
		INTO @LINE_NO
			,@JUCHU_KBN
			,@TOKUISAKI_CD
			,@HINMOKU_SEQ
			,@SOKO_CD
			,@SHUKKA_YOTEI_DATE
			,@YOYAKU_DENPYO_NO
			,@YOYAKU_DENPYO_ENO
			,@SHUKKO_KBN

		--������
		SET @SURYO = NULL
		SET @IS_ZAIKO_KANRI = NULL
	END

	CLOSE tmp_CUR
	DEALLOCATE tmp_CUR

	/*===============================���ʈ���END===============================*/

	/*===============================���ʈ�����`�F�b�NSTART===============================*/
	/*===============================���ʈ�����`�F�b�NEND===============================*/

	/*===============================�^�M���x�z�`�F�b�NSTART===============================*/
	--�`�F�b�N���s�����߂ɋ��z�֌W�����߂�
	UPDATE #tmp
	SET TAX_SITEI_KBN = CASE WHEN TORI_GAIKA.TUKA_CD = @TUKA_CD	--�ŗ��w��敪
								THEN #tmp.KAZEI_KBN
							--�O�݂͔�ېŌŒ�
							ELSE '02'
							END
		,JUCHU_TANKA =  CASE WHEN #tmp.SAMPLE_SHUKKA_FLG = '1'
									--�T���v���o��
									THEN 0
						ELSE CASE WHEN TORI_GAIKA.TUKA_CD = @TUKA_CD
									THEN CASE --�|�����ݒ肳��Ă���ꍇ�v
												WHEN KAKERITU IS NOT NULL
													THEN dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, (CONVERT(DECIMAL(5, 2),KAKERITU) * TANKA.SOTOZEI_TANKA) / 100, 0, 0)
												--�|�����ݒ肾���A�����ʉݒP�����ݒ肳��Ă���ꍇ
												WHEN TORIHIKISAKI_TUKA_TANKA IS NOT NULL
													--�~�݂̏ꍇ�A���[�g��1�ƂȂ�
													THEN dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, TORIHIKISAKI_TUKA_TANKA, 0, 0)
												--���Ӑ�ʒP�����ݒ肳��Ă���ꍇ
												WHEN TOKUI_TANKA.SOTOZEI_TANKA IS NOT NULL
													THEN dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, TOKUI_TANKA.SOTOZEI_TANKA, 0, 0)
												--���Ӑ�ʊ|�����ݒ肳��Ă���ꍇ
												WHEN TOKUI_TANKA.KAKERITSU IS NOT NULL
													THEN dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, TOKUI_TANKA.KAKERITSU * TANKA.SOTOZEI_TANKA, 0, 0)
												--�e���Ӑ�̓��Ӑ�ʒP�����ݒ肳��Ă���ꍇ
												WHEN OYA_TOKUI_TANKA.SOTOZEI_TANKA IS NOT NULL
													THEN dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, OYA_TOKUI_TANKA.SOTOZEI_TANKA, 0, 0)
												--�e���Ӑ�ʊ|�����ݒ肳��Ă���ꍇ
												WHEN OYA_TOKUI_TANKA.KAKERITSU IS NOT NULL
													THEN dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, OYA_TOKUI_TANKA.KAKERITSU * TANKA.SOTOZEI_TANKA, 0, 0)
												--�i�ڊ|���ݒ肩�����C�O�敪������������`�ԋ敪���X��(�O��)�X��(����)�łȂ�
												WHEN HIN_EX.HINMOKU_KAKERITU IS NOT NULL AND TORIHIKI_EX.KOKUNAI_KAIGAI_KBN = '01'
														AND TOKUI_EX.TORIHIKI_KEITAI_KBN NOT IN ('4', '5')
													THEN dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, HIN_EX.HINMOKU_KAKERITU * TANKA.SOTOZEI_TANKA, 0, 0)
												--���Ӑ�}�X�^�̓��Ӑ�ʊ|�����ݒ肳��Ă���ꍇ
												WHEN TOKUI_EX.KAKERITSU IS NOT NULL
													THEN dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, TOKUI_EX.KAKERITSU  * TANKA.SOTOZEI_TANKA, 0, 0)
												--��L�ɑ����Ȃ��ꍇ�A�i�ڒP��
												ELSE dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, TANKA.SOTOZEI_TANKA, 0, 0)
											END
								--�O�݂̏ꍇ�A�����ʉݒP�� *���[�g
								ELSE dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, CONVERT(DECIMAL(13, 3), TORIHIKISAKI_TUKA_TANKA) * ISNULL(CONVERT(DECIMAL(8, 3),#tmp.RATE), RATE.RATE), 0, 1)
							END
						END
		,KAKERITU = CASE WHEN #tmp.SAMPLE_SHUKKA_FLG = '1'
									--�T���v���o��
									THEN 0
					ELSE CASE WHEN TORI_GAIKA.TUKA_CD = @TUKA_CD
								THEN CASE --�|�����ݒ肳��Ă���ꍇ�v
											WHEN KAKERITU IS NOT NULL
												THEN CONVERT(DECIMAL(5, 2),KAKERITU) / 100
											--�|�����ݒ肾���A�����ʉݒP�����ݒ肳��Ă���ꍇ
											WHEN TORIHIKISAKI_TUKA_TANKA IS NOT NULL
												--�~�݂̏ꍇ�A���[�g��1�ƂȂ�
												THEN --�����ʉݒP�� > �i�ڒP���̏ꍇ�A�|���͖��ݒ�
														CASE WHEN CONVERT(DECIMAL(14, 4), TORIHIKISAKI_TUKA_TANKA) >= TANKA.SOTOZEI_TANKA OR TANKA.SOTOZEI_TANKA = 0
																	THEN NULL
															--(�󒍒P��/���P��(�O�ŒP��):������2�ʂ��l�̌ܓ�
															ELSE [dbo].[CO_FUNC_HASU_SHORI](CONVERT(DECIMAL(4, 3), (CONVERT(DECIMAL(14, 4), TORIHIKISAKI_TUKA_TANKA) / TANKA.SOTOZEI_TANKA)), '01', 3)
														END
											--���Ӑ�ʒP�����ݒ肳��Ă���ꍇ
											WHEN TOKUI_TANKA.SOTOZEI_TANKA IS NOT NULL
												THEN NULL
											--���Ӑ�ʊ|�����ݒ肳��Ă���ꍇ
											WHEN TOKUI_TANKA.KAKERITSU IS NOT NULL
												THEN TOKUI_TANKA.KAKERITSU
											--�e���Ӑ�̓��Ӑ�ʒP�����ݒ肳��Ă���ꍇ
											WHEN OYA_TOKUI_TANKA.SOTOZEI_TANKA IS NOT NULL
												THEN NULL
											--�e���Ӑ�ʊ|�����ݒ肳��Ă���ꍇ
											WHEN OYA_TOKUI_TANKA.KAKERITSU IS NOT NULL
												THEN OYA_TOKUI_TANKA.KAKERITSU
											--�i�ڊ|���ݒ肩�����C�O�敪������������`�ԋ敪���X��(�O��)�X��(����)�łȂ�
											WHEN HIN_EX.HINMOKU_KAKERITU IS NOT NULL AND TORIHIKI_EX.KOKUNAI_KAIGAI_KBN = '01'
													AND TOKUI_EX.TORIHIKI_KEITAI_KBN NOT IN ('4', '5')
												THEN HIN_EX.HINMOKU_KAKERITU
											--���Ӑ�}�X�^�̓��Ӑ�ʊ|�����ݒ肳��Ă���ꍇ
											WHEN TOKUI_EX.KAKERITSU IS NOT NULL
												THEN TOKUI_EX.KAKERITSU
											--��L�ɑ����Ȃ��ꍇ�A�|�����ݒ�
											ELSE NULL
										END
							--�O�݂̏ꍇ�A�|�����ݒ�
							ELSE NULL
						END
					END
		,KAKERITU_REF_KBN = CASE WHEN #tmp.KAKERITU_REF_KBN IS NOT NULL 
									THEN #tmp.KAKERITU_REF_KBN
							ELSE CASE WHEN #tmp.SAMPLE_SHUKKA_FLG = '1'
									--�T���v���o��
									THEN NULL
							ELSE CASE WHEN TORI_GAIKA.TUKA_CD = @TUKA_CD
											THEN CASE --�|�����ݒ肳��Ă���ꍇ�v
														WHEN KAKERITU IS NOT NULL
															THEN NULL
														--�|�����ݒ肾���A�����ʉݒP�����ݒ肳��Ă���ꍇ
														WHEN TORIHIKISAKI_TUKA_TANKA IS NOT NULL
															THEN NULL
														--���Ӑ�ʒP�����ݒ肳��Ă���ꍇ
														WHEN TOKUI_TANKA.SOTOZEI_TANKA IS NOT NULL
															THEN '01'
														--���Ӑ�ʊ|�����ݒ肳��Ă���ꍇ
														WHEN TOKUI_TANKA.KAKERITSU IS NOT NULL
															THEN '01'
														--�e���Ӑ�̓��Ӑ�ʒP�����ݒ肳��Ă���ꍇ
														WHEN OYA_TOKUI_TANKA.SOTOZEI_TANKA IS NOT NULL
															THEN '02'
														--�e���Ӑ�ʊ|�����ݒ肳��Ă���ꍇ
														WHEN OYA_TOKUI_TANKA.KAKERITSU IS NOT NULL
															THEN '02'
														--�i�ڊ|���ݒ肩�����C�O�敪������������`�ԋ敪���X��(�O��)�X��(����)�łȂ�
														WHEN HIN_EX.HINMOKU_KAKERITU IS NOT NULL AND TORIHIKI_EX.KOKUNAI_KAIGAI_KBN = '01'
																AND TOKUI_EX.TORIHIKI_KEITAI_KBN NOT IN ('4', '5')
															THEN '03'
														--���Ӑ�}�X�^�̓��Ӑ�ʊ|�����ݒ肳��Ă���ꍇ
														WHEN TOKUI_EX.KAKERITSU IS NOT NULL
															THEN '04'
														--��L�ɑ����Ȃ��ꍇ�A�|�����ݒ�
														ELSE NULL
													END
										--�O�݂̏ꍇ�A�|�����ݒ�
										ELSE NULL
									END
								END
							END
	FROM #tmp
	LEFT JOIN BC_MST_TANKA TANKA 
		ON TANKA.KAISHA_CD = @KAISHA_CD
		AND TANKA.HINMOKU_SEQ = #tmp.HINMOKU_SEQ
		AND DATEDIFF(DAY, START_DATE, DTL_SHUKKA_YOTEI_DATE) >= 0
		AND DATEDIFF(DAY, END_DATE, DTL_SHUKKA_YOTEI_DATE) <= 0
	LEFT JOIN BC_MST_TORIHIKISAKI_GAIKA TORI_GAIKA
		ON TORI_GAIKA.KAISHA_CD = @KAISHA_CD
		AND TORI_GAIKA.TORIHIKISAKI_CD = #tmp.TOKUISAKI_CD
	LEFT JOIN BC_MST_RATE RATE
		ON RATE.KAISHA_CD = TORI_GAIKA.KAISHA_CD
		AND RATE.BEFORE_TUKA_CD = TORI_GAIKA.TUKA_CD
		AND RATE.RATETYPE_CD = TORI_GAIKA.RATETYPE_CD
		AND DATEDIFF(DAY, RATE.START_DATE, DTL_SHUKKA_YOTEI_DATE) >= 0
		AND DATEDIFF(DAY, RATE.END_DATE, DTL_SHUKKA_YOTEI_DATE) <= 0
		AND RATE.DEL_FLG = 0
	LEFT JOIN BC_MST_TOKUISAKIBETU_TANKA TOKUI_TANKA
		ON TOKUI_TANKA.KAISHA_CD = @KAISHA_CD
		AND TOKUI_TANKA.TOKUISAKI_CD = #tmp.TOKUISAKI_CD
		AND TOKUI_TANKA.HINMOKU_SEQ = #tmp.HINMOKU_SEQ
		AND DATEDIFF(DAY, TOKUI_TANKA.START_DATE, DTL_SHUKKA_YOTEI_DATE) >= 0
		AND DATEDIFF(DAY, TOKUI_TANKA.END_DATE, DTL_SHUKKA_YOTEI_DATE) <= 0
		AND TOKUI_TANKA.DEL_FLG = 0
		AND TOKUI_TANKA.MUKOU_FLG = 0
	LEFT JOIN BC_MST_TORIHIKISAKI_EX TORIHIKI_EX
		ON TORIHIKI_EX.KAISHA_CD = @KAISHA_CD
		AND TORIHIKI_EX.TORIHIKISAKI_CD = #tmp.TOKUISAKI_CD
	LEFT JOIN BC_MST_TOKUISAKI_EX TOKUI_EX
		ON TOKUI_EX.KAISHA_CD = @KAISHA_CD
		AND TOKUI_EX.TOKUISAKI_CD = #tmp.TOKUISAKI_CD
	LEFT JOIN BC_MST_TOKUISAKIBETU_TANKA OYA_TOKUI_TANKA
		ON OYA_TOKUI_TANKA.KAISHA_CD = @KAISHA_CD
		AND OYA_TOKUI_TANKA.TOKUISAKI_CD = TOKUI_EX.OYA_TOKUISAKI_CD
		AND OYA_TOKUI_TANKA.HINMOKU_SEQ = #tmp.HINMOKU_SEQ
		AND DATEDIFF(DAY, OYA_TOKUI_TANKA.START_DATE, DTL_SHUKKA_YOTEI_DATE) >= 0
		AND DATEDIFF(DAY, OYA_TOKUI_TANKA.END_DATE, DTL_SHUKKA_YOTEI_DATE) <= 0
		AND OYA_TOKUI_TANKA.DEL_FLG = 0
		AND OYA_TOKUI_TANKA.MUKOU_FLG = 0
	LEFT JOIN BC_MST_HINMOKU_KANRI HINKAN
		ON HINKAN.KAISHA_CD = @KAISHA_CD
		AND HINKAN.HINMOKU_SEQ = #tmp.HINMOKU_SEQ
	LEFT JOIN BC_MST_HINMOKU HIN
		ON HIN.KAISHA_CD = HINKAN.KAISHA_CD
		AND HIN.HINMOKU_CD = HINKAN.HINMOKU_CD
	LEFT JOIN BC_MST_HINMOKU_EX HIN_EX
		ON HIN_EX.KAISHA_CD = HINKAN.KAISHA_CD
		AND HIN_EX.HINMOKU_CD = HINKAN.HINMOKU_CD
	LEFT JOIN BC_MST_TUKA TUKA
		ON TORI_GAIKA.KAISHA_CD = TUKA.KAISHA_CD
		AND TORI_GAIKA.TUKA_CD = TUKA.TUKA_CD
		AND TUKA.DEL_FLG = 0
		AND TUKA.MUKOU_FLG = 0

	UPDATE #tmp
	SET KAZEI_KBN = CASE WHEN TORI_GAIKA.TUKA_CD = @TUKA_CD		--�ېŋ敪
							--�~�݂̏ꍇ
							THEN CASE WHEN #tmp.KAZEI_KBN = '02'
											THEN '02'
									ELSE '01'
									END
							--�O�݂͔�ېŌŒ�
							ELSE '02'
					END
		,TAX_RATE = CASE WHEN TORI_GAIKA.TUKA_CD = @TUKA_CD
								--�~�݂̏ꍇ
								THEN dbo.CO_FUNC_GET_TAXRATE(@KAISHA_CD, TAX_SITEI_KBN, HIN.TAX_KBN_CD, DTL_SHUKKA_YOTEI_DATE)
							--�O�݂͔�ې�
							ELSE 0.00
					END
		--�����ʉݒP�����~�݂̏ꍇ�̍l��
		,TORIHIKISAKI_TUKA_TANKA = CASE WHEN TORI_GAIKA.TUKA_CD = @TUKA_CD
												THEN JUCHU_TANKA
										--�O�݂̏ꍇ�͎l�̌ܓ��Œ�
										ELSE dbo.CO_FUNC_HASU_SHORI_EX(TORIHIKISAKI_TUKA_TANKA, '01', TUKA.DECIMAL_LENGTH)
									END
		--���[�g�̉~�݂̍l��
		,RATE = CASE WHEN TORI_GAIKA.TUKA_CD = @TUKA_CD
						THEN '1'
						ELSE ISNULL(#tmp.RATE, RATE.RATE)
					END
	FROM #tmp
	LEFT JOIN BC_MST_TORIHIKISAKI_GAIKA TORI_GAIKA
		ON TORI_GAIKA.KAISHA_CD = @KAISHA_CD
		AND TORI_GAIKA.TORIHIKISAKI_CD = #tmp.TOKUISAKI_CD
	LEFT JOIN BC_MST_RATE RATE
		ON RATE.KAISHA_CD = TORI_GAIKA.KAISHA_CD
		AND RATE.BEFORE_TUKA_CD = TORI_GAIKA.TUKA_CD
		AND RATE.RATETYPE_CD = TORI_GAIKA.RATETYPE_CD
		AND DATEDIFF(DAY, RATE.START_DATE, DTL_SHUKKA_YOTEI_DATE) >= 0
		AND DATEDIFF(DAY, RATE.END_DATE, DTL_SHUKKA_YOTEI_DATE) <= 0
		AND RATE.DEL_FLG = 0
	LEFT JOIN BC_MST_HINMOKU_KANRI HINKAN
		ON HINKAN.KAISHA_CD = @KAISHA_CD
		AND HINKAN.HINMOKU_SEQ = #tmp.HINMOKU_SEQ
	LEFT JOIN BC_MST_HINMOKU HIN
		ON HIN.KAISHA_CD = HINKAN.KAISHA_CD
		AND HIN.HINMOKU_CD = HINKAN.HINMOKU_CD
	LEFT JOIN BC_MST_TUKA TUKA
		ON TORI_GAIKA.KAISHA_CD = TUKA.KAISHA_CD
		AND TORI_GAIKA.TUKA_CD = TUKA.TUKA_CD
		AND TUKA.DEL_FLG = 0
		AND TUKA.MUKOU_FLG = 0

	--�`�F�b�N
	--������P�ʂɗ^�M���x�`�F�b�N�����{
	DECLARE @SEIKYUSAKI_CD NVARCHAR(15)
		   ,@YOSHIN_TAISHO_KINGAKU DECIMAL
		   ,@YOSHIN_GENDO_GAKU DECIMAL(18)
		   ,@YOSHIN_GENDO_ZANDAKA DECIMAL(18)

	DECLARE yoshinCUR CURSOR FOR
	SELECT DISTINCT SEIKYUSAKI_CD
	FROM #tmp
	WHERE ERROR_MSG IS NULL
	AND JUCHU_KBN = '01'

	OPEN yoshinCUR
	FETCH NEXT FROM yoshinCUR
	INTO @SEIKYUSAKI_CD
	WHILE @@FETCH_STATUS = 0
	BEGIN
		
		--�^�M���x�Ώۋ��z�̎擾
		SELECT @YOSHIN_TAISHO_KINGAKU = dbo.HK_FUNC_GET_YOSHIN_TAISHO_KINGAKU(@KAISHA_CD, @SEIKYUSAKI_CD)

		--@YOSHIN_TAISHO_KINGAKU��NULL�̏ꍇ�A�^�M���x�z�����ݒ�
		IF (@YOSHIN_TAISHO_KINGAKU IS NOT NULL)
		BEGIN
			--�^�M���x�z�̎擾
			SELECT @YOSHIN_GENDO_GAKU
					= CASE WHEN SEIKYU.YOSHIN_GRP_CD IS NULL
							THEN SEIKYU.YOSHIN_GENDOGAKU	--������̗^�M���x�z
						   ELSE YOSHI_G.YOSHIN_GENDOGAKU	--�^�M�O���[�v�̗^�M���x�z
					  END
			FROM BC_MST_SEIKYUSAKI SEIKYU
			LEFT JOIN BC_MST_YOSHIN_GRP YOSHI_G
				ON YOSHI_G.KAISHA_CD = SEIKYU.KAISHA_CD
				AND YOSHI_G.YOSHIN_GRP_CD = SEIKYU.YOSHIN_GRP_CD
				AND YOSHI_G.DEL_FLG = 0
			WHERE SEIKYU.SEIKYUSAKI_CD = @SEIKYUSAKI_CD

			--�^�M���x�c�����^�M���x�z-�^�M�Ώۋ��z
			SET @YOSHIN_GENDO_ZANDAKA = @YOSHIN_GENDO_GAKU - @YOSHIN_TAISHO_KINGAKU

			--�^�M���x�z�c�����v���X�̏ꍇ�A����o�^���̋��z���l������
			IF(@YOSHIN_GENDO_ZANDAKA >= 0)
			BEGIN
				--����o�^�ɂ����x�c�������߂�B
				--@YOSHIN_GENDO_ZANDAKA-((������ɊY������󒍋��z�{�����)�̍��v)�����߂�
				SELECT @YOSHIN_GENDO_ZANDAKA
						= @YOSHIN_GENDO_ZANDAKA - 
						  SUM(CASE WHEN #tmp.SHUKKO_KBN IN ('04', '06')
										THEN 0
									ELSE (dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, JUCHU_TANKA * SURYO, 1, 0)	--���z
										  + dbo.CO_FUNC_HASU_SHORI((JUCHU_TANKA * SURYO) * TAX_RATE, TORI.JUCHU_SHOHIZEI_HASU_KBN, 0)	--�����
										 )
							  END
						     )
				FROM #tmp
				LEFT JOIN BC_MST_TORIHIKISAKI TORI
					ON TORI.KAISHA_CD = @KAISHA_CD
					AND TORI.TORIHIKISAKI_CD = #tmp.TOKUISAKI_CD
				WHERE SEIKYUSAKI_CD = @SEIKYUSAKI_CD
				AND JUCHU_KBN = '01'	--�{�󒍂̋��z���Ώ�
			END
			
			IF(@YOSHIN_GENDO_ZANDAKA < 0)
			BEGIN
				UPDATE #tmp
				SET ERROR_MSG = @ERR_MSG_YOSHIN_GENDO + @SEIKYUSAKI_CD
				WHERE SEIKYUSAKI_CD = @SEIKYUSAKI_CD
			END
		END

		--������
		SET @YOSHIN_TAISHO_KINGAKU = NULL
		SET @YOSHIN_GENDO_GAKU = NULL
		SET @YOSHIN_GENDO_ZANDAKA = NULL

		FETCH NEXT FROM yoshinCUR
		INTO @SEIKYUSAKI_CD
	END

	CLOSE yoshinCUR
	DEALLOCATE yoshinCUR

	END

	/*===============================�^�M���x�z�`�F�b�NEND===============================*/

	--�G���[�s
	DECLARE @ERR_CNT INT
    --�G���[�s��ϐ�@ERR_CNT�ɐݒ肷��
    SELECT @ERR_CNT = COUNT(*)
    FROM #tmp
	WHERE ERROR_MSG IS NOT NULL

	IF (@ERR_CNT > 0)
	BEGIN
		--�G���[����
		SELECT @RetCd
		
		--�G���[���擾
		SELECT LINE_NO				AS �s�ԍ�
	   ,ERROR_MSG					AS �G���[���
	   ,JUCHU_KBN					AS �󒍋敪
	   ,JUCHU_DATE					AS �󒍓�
	   ,SHUKKO_KBN					AS �o�ɋ敪
	   ,TOKUISAKI_CD				AS ���Ӑ�R�[�h
	   ,SHUKKASAKI_CD				AS �w�b�_�o�א�R�[�h
	   ,SEIKYUSAKI_CD				AS ������R�[�h
	   ,SOKO_CD						AS �w�b�_�q�ɃR�[�h
	   ,AZUKE_AZUKARI_IDO_SOKO_CD	AS �a���a����ړ��q�ɃR�[�h
	   ,SHUKKA_YOTEI_DATE			AS �w�b�_�o�ח\���
	   ,SHITEI_NOHIN_DATE			AS �w�b�_�w��[�i��
	   ,SHITEI_NOHIN_JIKOKU			AS �w��[�i����
	   ,HAISOU_KBN					AS �z���敪
	   ,KESSAI_HOHO					AS ���ϕ��@
	   ,HDR_GEDAIMACHI_FLG			AS ����҂��t���O
	   ,SAMPLE_SHUKKA_FLG			AS �T���v���o�׃t���O
	   ,HIKIATE_CHOSEI_FUYO_FLG		AS ���������s�p�t���O
	   ,HDR_SEIKYU_KIJUN_DATE		AS �w�b�_�������
	   ,TOKUISAKI_DENPYO_NO			AS ���Ӑ�`�[NO
	   ,TOKUISAKI_HACCHU_NO			AS ���Ӑ攭��NO
	   ,BUNRUI_CD					AS ���ރR�[�h
	   ,URIBA_NM					AS ���ꖼ
	   ,TANTOSHA_NM					AS �S���Җ�
	   ,NAISEN_NO					AS �����ԍ�
	   ,TANTOSHA_CD					AS �S���҃R�[�h
	   ,TANTO_BUSHO_CD				AS �S�������R�[�h
	   ,NOHIN_KBN					AS �[�i�敪
	   ,RYUTU_KAKOU_KBN				AS ���ʉ��H�敪
	   ,BIKO						AS �w�b�_���l
	   ,JUCHU_COMMENT				AS �󒍃R�����g
	   ,SOKO_COMMENT				AS �q�ɃR�����g
	   ,PROJECT_CD					AS �v���W�F�N�g�R�[�h
	   ,HANBAI_AREA_CD				AS �̔��G���A�R�[�h
	   ,YOYAKU_KAIHO_KIGEN			AS �\��������
	   ,HINMOKU						AS �i��
	   ,LOT_NUM						AS ���b�g��
	   ,BARA_NUM					AS �o����
	   ,SUITEI_KAKUTEI_KBN			AS ����m��敪
	   ,KAKERITU					AS �|��
	   ,HIKIATE_STATE				AS �������
	   ,DTL_GEDAIMACHI_FLG			AS ���׉���҂��t���O
	   ,DTL_SOKO_CD					AS ���בq�ɃR�[�h
	   ,TEKIYO						AS �E�v
	   ,DTL_SHUKKASAKI_CD			AS ���׏o�א�R�[�h
	   ,DTL_SHUKKA_YOTEI_DATE		AS ���׏o�ח\���
	   ,DTL_SHITEI_NOHIN_DATE		AS ���׎w��[�i��
	   ,DTL_SEIKYU_KIJUN_DATE		AS ���א������
	   ,YOYAKU_DENPYO_NO			AS �\��`�[NO
	   ,YOYAKU_DENPYO_ENO			AS �\��`�[�}��
	   ,KAZEI_KBN					AS �ېŋ敪
	   ,TORIHIKISAKI_TUKA_TANKA		AS �����ʉݒP��
	   ,RATE						AS ���[�g
	   ,DTL_BIKO					AS ���ה��l
	 
		FROM #tmp	
		WHERE 	ERROR_MSG IS NOT NULL
		ORDER BY LINE_NO

		--�G���[�s�A���̏ꍇ�A�x�����͎擾���Ȃ��B
		--�x���Ȃ�(�󃌃R�[�h)�Ƃ��ĕԂ�
		SELECT 0
		WHERE 1 = 0

		--�G���[�s�A���̏ꍇ�A�o�^�`�[FROM�ATO��(�󃌃R�[�h)�Ƃ��ĕԂ�
		SELECT 0
		WHERE 1 = 0
	END
	ELSE
	BEGIN
		--�G���[�Ȃ�
		/*===============================�󒍔ԍ��̔ԏ���START===============================*/
		--�󒍔ԍ��̍̔Ԃ����s����
		DECLARE @INS_CNT	INT
		DECLARE @KETA		DECIMAL(2,0)
		DECLARE @GET_NO_S	DECIMAL(10,0) 
		DECLARE @GET_NO_E	DECIMAL(10,0)
		DECLARE @RET_STATUS INT

		--�̔Ԑ����擾
		SELECT @INS_CNT = COUNT(*)
		FROM #tmpHdr

		--�X�g�A�h�v���V�[�W���[�uGET_NEXT_SAIBAN_TIMEOUT_ON�v���ďo���A�ԍ����擾����
		EXEC @RET_STATUS = GET_NEXT_SAIBAN_TIMEOUT_ON @KAISHA_CD
											,'HKJC'
											,'@NONPREFIX@'
											,@INS_CNT
											,@USER_ID
											,@PGM_CD
											,@KETA OUTPUT
											,@GET_NO_S OUTPUT
											,@GET_NO_E OUTPUT
			
		--�߂�l��0�ȊO�̏ꍇ�͍̔Ԏ��s
		IF(@RET_STATUS <> 0)
		BEGIN
			--�ϐ����^�[���R�[�h��2��ݒ肵
			SET @RetCd = 2
			--�I�������ɃW�����v
			GOTO END_PROC
		END
			
		--#tmpHdr�ɓ`�[�ԍ���ݒ肷��
		--�`�[�ԍ��FRIGHT(@KETA����0���� + @GET_NO_S(�̔ԊJ�n�ԍ�) + #tmpHdr�s�ԍ� - 1), @KETA)
		UPDATE #tmpHdr
		SET DENPYO_NO = #tmpHdrNo.DENPYO_NO
		FROM #tmpHdr
		INNER JOIN (SELECT GROUP_KEY
							,RIGHT(REPLICATE('0', @KETA)  + CONVERT(NVARCHAR, (@GET_NO_S + ROW_NUMBER() OVER (ORDER BY GROUP_KEY) -1)) , @KETA) AS DENPYO_NO
					FROM #tmpHdr
					) #tmpHdrNo
			ON #tmpHdr.GROUP_KEY = #tmpHdrNo.GROUP_KEY

		--�ϐ��̏�����
		SET @INS_CNT = NULL
		SET @KETA = NULL
		SET @GET_NO_S = NULL 
		SET @GET_NO_E = NULL
		SET @RET_STATUS = NULL		

		--#tmp�ɓ`�[�ԍ���ݒ肷��
		UPDATE #tmp
		SET DENPYO_NO = #tmpHdr.DENPYO_NO
		FROM #tmp
		INNER JOIN #tmpHdr
			ON #tmp.GROUP_KEY = #tmpHdr.GROUP_KEY

		--#tmp�Ɏ󒍎}�Ԃ�ݒ肷��
		UPDATE #tmp
		SET DENPYO_ENO = T_ENO.ENO
		FROM #tmp
		INNER JOIN (SELECT LINE_NO
					      ,ROW_NUMBER() OVER(PARTITION BY #tmp.GROUP_KEY ORDER BY #tmp.LINE_NO) AS ENO
					FROM #tmp
				   ) T_ENO
			ON #tmp.LINE_NO = T_ENO.LINE_NO
		/*===============================�󒍔ԍ��̔ԏ���END===============================*/

		/*===============================�o�^����START===============================*/
		
		--���ݓ�����ϐ��ɐݒ�
		DECLARE @NOW DATETIME = GETDATE()

		--�󒍃w�b�_
		INSERT INTO HK_TBL_JUCHU_HDR
		(KAISHA_CD
		,JUCHU_NO
		,KAKUTEI_KBN
		,WF_SHONIN_STATUS
		,JUCHU_DATE
		,TOKUISAKI_CD
		,TOKUISAKI_TANTOSHA_NM
		,TANTO_BUSHO_CD
		,TANTOSHA_CD
		,PROJECT_CD
		,HAMBAI_AREA_CD
		,TEKIYO
		,SHUKKASAKI_CD
		,SEIKYUSAKI_CD
		,KAISHU_HOHO_PATTERN
		,SEIKYU_DATE
		,SHUKKA_YOTEI_DATE
		,SHUKKO_KBN
		,UCHIZEI_SOTOZEI_KBN
		,SHOHIZEI_KBN
		,HENPIN_MOTO_SHIRE_NO
		,HENKYAKU_KIGEN
		,CHOKUSO_HACCHU_NO
		,HDR_JIDO_BUNNO_FLG
		,CANCEL_FLG
		,CANCEL_RIYU
		,CANCEL_TM
		,EDI_FLG
		,EDI_TORIHIKI_NO
		,EDI_TORIKOMI_FLG
		,EDI_TORIHIKI_CANCEL_FLG
		,EDI_SEND_STATUS
		,EDI_TORIHIKI_RIREKI_SEQ
		,DEL_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD						--��ЃR�[�h
			  ,HDR.DENPYO_NO					--�`�[�ԍ�
			  ,NULL								--�m��敪
			  ,'01'								--WF���F��ԁF���\��
			  ,CONVERT(DATE, HDR.JUCHU_DATE)	--�󒍓�
			  ,HDR.TOKUISAKI_CD					--���Ӑ�R�[�h
			  ,HDR.TANTOSHA_NM					--���Ӑ�S���Җ�
			  ,ISNULL(HDR.TANTO_BUSHO_CD, TOKUI.KITEI_TANTO_BUSHO_CD)	--�S�������R�[�h
			  ,ISNULL(HDR.TANTOSHA_CD, TOKUI.KITEI_TANTOSHA_CD)			--�S���҃R�[�h
			  ,HDR.PROJECT_CD					--�v���W�F�N�g�R�[�h
			  ,HDR.HANBAI_AREA_CD				--�̔��G���A�R�[�h
			  ,CASE WHEN HDR.JUCHU_KBN = '03'	--�E�v
						THEN '�q�Ɉړ�'
					ELSE NULL
			   END
			  ,HDR.SHUKKASAKI_CD				--�o�א�R�[�h
			  ,HDR.SEIKYUSAKI_CD				--������R�[�h
			  ,SEIKYU_HOHO.KAISHU_HOHO_PATTERN	--������@�p�^�[��
			  ,CASE WHEN HDR.JUCHU_KBN = '01'	--������
						THEN CASE --�s�x�̏ꍇ
								  WHEN SEIKYU_HOHO.SEIKYU_TYPE = '99'
										THEN --���������NULL�̏ꍇ�A�o�ח\���
											 CONVERT(DATE,ISNULL(HDR.HDR_SEIKYU_KIJUN_DATE, HDR.SHUKKA_YOTEI_DATE))
										--�s�x�łȂ��ꍇ
										ELSE NULL
							 END
					ELSE NULL
			   END
			  ,CONVERT(DATE, HDR.SHUKKA_YOTEI_DATE)	--�o�ח\���
			  ,HDR.SHUKKO_KBN					--�o�ɋ敪
			  ,'01'								--���ŊO�ŋ敪�F�O�ŌŒ�
			  ,TORIHIKI.JUCHU_SHOHIZEI_KBN		--�󒍏���ŋ敪�F�����̎󒍏���ŋ敪
			  ,NULL								--�ԕi���d��NO
			  ,NULL								--�ԋp����
			  ,NULL								--��������NO
			  ,0								--�������[�t���O�F�u���Ȃ��v�Œ�(�g�p���Ȃ�
			  ,0								--����t���O
			  ,NULL								--������R
			  ,NULL								--�������
			  ,0								--EDI�t���O
			  ,NULL								--EDI����ԍ�
			  ,0								--EDI�捞�t���O
			  ,0								--EDI����L�����Z���t���O
			  ,0								--EDI���M���
			  ,NULL								--EDI��������V�[�P���X�ԍ�
			  ,0								--�폜�t���O
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmpHdr HDR
		LEFT JOIN BC_MST_KAISHU_HOHO SEIKYU_HOHO
			ON SEIKYU_HOHO.KAISHA_CD = @KAISHA_CD
			AND SEIKYU_HOHO.SEIKYUSAKI_CD = HDR.SEIKYUSAKI_CD
			AND SEIKYU_HOHO.KAISHU_HOHO_FLG = 1	--�D�������@
		LEFT JOIN BC_MST_TORIHIKISAKI TORIHIKI
			ON TORIHIKI.KAISHA_CD = @KAISHA_CD
			AND TORIHIKI.TORIHIKISAKI_CD = HDR.TOKUISAKI_CD
		LEFT JOIN BC_MST_TOKUISAKI TOKUI
			ON TOKUI.KAISHA_CD = @KAISHA_CD
			AND TOKUI.TOKUISAKI_CD = HDR.TOKUISAKI_CD

		--�󒍃w�b�_�O��
		INSERT INTO HK_TBL_JUCHU_HDR_GAIKA
		(KAISHA_CD
		,JUCHU_NO
		,TUKA_CD
		,DEL_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD
			  ,HDR.DENPYO_NO
			  ,TORIHIKI.TUKA_CD
			  ,0
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM  #tmpHdr HDR
		LEFT JOIN BC_MST_TORIHIKISAKI_GAIKA TORIHIKI
			ON TORIHIKI.KAISHA_CD = @KAISHA_CD
			AND TORIHIKI.TORIHIKISAKI_CD = HDR.TOKUISAKI_CD

		--�󒍃w�b�_�g��
		INSERT INTO HK_TBL_JUCHU_HDR_EX
		(KAISHA_CD
		,JUCHU_NO
		,JUCHU_KBN
		,YOYAKU_KAIHO_KIGEN
		,TOKUISAKI_DENPYO_NO
		,TOKUISAKI_HACCHU_NO
		,SEIKYU_KIJUN_DATE
		,SOKO_CD
		,NOHIN_KBN
		,SHITEI_NOHIN_DATE
		,SHITEI_NOHIN_JIKOKU
		,HAISO_KBN
		,KESSAI_HOHO
		,RYUTU_KAKO_KBN
		,URIBA_NM
		,NAISEN_NO
		,HIKIATE_CHOSEI_FUYO_FLG
		,GEDAI_MACHI_FLG
		,SAMPLE_SYUKKA_FLG
		,BUNRUI_CD
		,JUCHU_COMMENT
		,SOKO_COMMENT
		,BIKO
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD
			  ,HDR.DENPYO_NO
			  ,HDR.JUCHU_KBN
			  ,CASE WHEN JUCHU_KBN = '02'	--�\��������
							THEN DATEADD(DAY, 14, CONVERT(DATE, HDR.SHUKKA_YOTEI_DATE))
					ELSE NULL
			   END
			  ,HDR.TOKUISAKI_DENPYO_NO
			  ,HDR.TOKUISAKI_HACCHU_NO
			  --���������NULL�̏ꍇ�A�o�ח\���
			  ,CONVERT(DATE, ISNULL(HDR_SEIKYU_KIJUN_DATE, SHUKKA_YOTEI_DATE))
			  ,HDR.SOKO_CD
			  --�[�i�敪��NULL�̏ꍇ�A�o�א�̔[�i�敪
			  ,CASE 
			  WHEN ISNULL(HDR.NOHIN_KBN, SHUKKA.NOHIN_KBN) IS NULL THEN '99'
			  ELSE ISNULL(HDR.NOHIN_KBN, SHUKKA.NOHIN_KBN)
			  END 
			  ,CONVERT(DATE, HDR.SHITEI_NOHIN_DATE)
			  ,HDR.SHITEI_NOHIN_JIKOKU
			  --�z���敪��NULL�̏ꍇ�A�o�א�̔z���敪
			  ,ISNULL(HDR.HAISOU_KBN, SHUKKA.HAISO_KBN)
			  ,KESSAI_HOHO
			  --���ʉ��H�敪��NULL�̏ꍇ�A���Ӑ�̐旬�ʉ��H�敪
			  ,ISNULL(HDR.RYUTU_KAKOU_KBN, TOKUISAKI.NOHINSHO_RYUTU_KAKO_KBN)
			  ,HDR.URIBA_NM
			  ,HDR.NAISEN_NO
			  ,ISNULL(HDR.HIKIATE_CHOSEI_FUYO_FLG, 0)
			  ,ISNULL(HDR.HDR_GEDAIMACHI_FLG, 0)
			  ,ISNULL(HDR.SAMPLE_SHUKKA_FLG, 0)
			  ,HDR.BUNRUI_CD
			  ,HDR.JUCHU_COMMENT
			  ,HDR.SOKO_COMMENT
			  ,HDR.BIKO
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmpHdr HDR
		LEFT JOIN BC_MST_SHUKKASAKI_EX SHUKKA
			ON SHUKKA.KAISHA_CD = @KAISHA_CD
			AND SHUKKA.SHUKKASAKI_CD = HDR.SHUKKASAKI_CD
		LEFT JOIN BC_MST_TOKUISAKI_EX TOKUISAKI
			ON TOKUISAKI.KAISHA_CD = @KAISHA_CD
			AND TOKUISAKI.TOKUISAKI_CD = HDR.TOKUISAKI_CD

		--�󒍓`�[����
		INSERT INTO HK_TBL_JUCHU_DTL
		(KAISHA_CD
		,JUCHU_NO
		,JUCHU_ENO
		,URIAGE_KBN
		,SHUKKO_KBN
		,HIKIATE_KBN
		,KAKUTEI_KBN
		,HINMOKU_SEQ
		,SHUKKASAKI_CD
		,LOT
		,SOKO_CD
		,AZUKARI_SOKO_CD
		,AZUKE_SOKO_CD
		,SHOHIN_LOT
		,NYUKA_YOTEI_NO
		,SHUKKA_YOTEI_DATE
		,NOHIN_YOTEI_DATE
		,KENSHU_YOTEI_DATE
		,IRISU
		,HAKOSU
		,NISUGATA_RENBAN
		,SURYO
		,TANI_GENKA
		,GENKA
		,TANKA
		,STD_TANKA
		,TANKA_KAKERITSU
		,KINGAKU
		,SHOHIZEI
		,TAX_RATE
		,KAZEI_KBN
		,KEIJO_STD_KBN
		,TEKIYO
		,BIKO
		,SHOKUTI_HINMOKU_NM
		,EDI_KEPPIN_FLG
		,GTIN_KBN_CD
		,TOKUISAKI_SHOHIN_CD
		,EDI_JUCHU_SURYO
		,TAX_SITEI_KBN
		,SET_NYUKA_YOTEI_SEQ
		,JIDO_BUNNO_FLG
		,TANI_GENKA_FLG
		,DEL_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD			--��ЃR�[�h
			  ,DENPYO_NO			--�`�[�ԍ�
			  ,DENPYO_ENO			--�}��
			  ,NULL					--����敪
			  ,#tmp.SHUKKO_KBN			--�o�ɋ敪
			  ,HIKIATE_STATE		--�������
			  ,CASE WHEN ISNULL(DTL_GEDAIMACHI_FLG, ISNULL(HDR_GEDAIMACHI_FLG, 0)) = '1'		--����m��敪
							--����҂��͐���
							THEN '01'
					ELSE SUITEI_KAKUTEI_KBN
			   END
			  ,#tmp.HINMOKU_SEQ		--�i��SEQ
			  ,DTL_SHUKKASAKI_CD	--�o�א�R�[�h
			  ,NULL					--���b�g
			  ,DTL_SOKO_CD			--�q�ɃR�[�h
			  --�a���蔄��̏ꍇ�̂ݐݒ�
			  ,CASE WHEN #tmp.SHUKKO_KBN = '03'	--�a����q�ɃR�[�h
							THEN AZUKE_AZUKARI_IDO_SOKO_CD
					ELSE NULL
			   END
			  --�a���o�ɂ̏ꍇ�̂ݐݒ�
			  ,CASE WHEN #tmp.SHUKKO_KBN = '06'	--�a���q�ɃR�[�h
							THEN AZUKE_AZUKARI_IDO_SOKO_CD
					ELSE NULL
			   END
			  ,NULL						--���i���b�g
			  ,NULL						--���ח\��NO
			  ,CONVERT(DATE, DTL_SHUKKA_YOTEI_DATE)	--�o�ח\���
			  ,CONVERT(DATE, DTL_SHITEI_NOHIN_DATE)	--�[�i�\���
			  ,NULL						--�����\���
			  ,HINMOKU.STD_IRISU		--����(�i�ڕW������)
			  ,NULL						--����
			  ,NULL						--���p�A��
			  ,SURYO					--����
			  ,NULL						--�P�ʌ���
			  ,NULL						--����
			  --�a����o�ɁA�a���o�ɂ͒P��0
			  ,CASE WHEN #tmp.SHUKKO_KBN IN ('04', '06')
							THEN 0
					ELSE JUCHU_TANKA
			   END
			  ,TANKA.SOTOZEI_TANKA		--�W���P��
			  ,KAKERITU					--�|��
			  --�a����o�ɁA�a���o�ɂ͋��z0
			  ,CASE WHEN #tmp.SHUKKO_KBN IN ('04', '06')
							THEN 0
					ELSE dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, JUCHU_TANKA * SURYO, 1, 0)
			   END
			  --�a����o�ɁA�a���o�ɂ͏����0
			  ,CASE WHEN #tmp.SHUKKO_KBN IN ('04', '06')
							THEN 0
					ELSE dbo.CO_FUNC_HASU_SHORI((JUCHU_TANKA * SURYO) * TAX_RATE, TORI.JUCHU_SHOHIZEI_HASU_KBN, 0)
			   END
			  ,TAX_RATE					--�ŗ�
			  ,#tmp.KAZEI_KBN				--�ېŋ敪
			  ,'01'						--�v���敪�F�o�׊�Œ�
			  ,TEKIYO					--�E�v
			  ,DTL_BIKO					--���l
			  ,NULL						--�����i�ږ�
			  ,0						--EDI���i�t���O
			  ,'999'					--GTIN�敪�R�[�h�F��ʂ̏����l
			  ,NULL						--���Ӑ揤�i�R�[�h
			  ,0						--EDI�󒍐���
			  ,TAX_SITEI_KBN			--�ŗ��w��敪
			  ,NULL						--�Z�b�g���ח\��SEQ
			  ,0						--�������[�t���O
			  ,0						--�P�ʌ����t���O
			  ,0						--�폜�t���O
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmp
		LEFT JOIN BC_MST_TANKA TANKA 
			ON TANKA.KAISHA_CD = @KAISHA_CD
			AND TANKA.HINMOKU_SEQ = #tmp.HINMOKU_SEQ
			AND DATEDIFF(DAY, START_DATE, DTL_SHUKKA_YOTEI_DATE) >= 0
			AND DATEDIFF(DAY, END_DATE, DTL_SHUKKA_YOTEI_DATE) <= 0
		LEFT JOIN BC_MST_TORIHIKISAKI TORI
			ON TORI.KAISHA_CD = @KAISHA_CD
			AND TORI.TORIHIKISAKI_CD = #tmp.TOKUISAKI_CD
		LEFT JOIN BC_MST_HINMOKU_KANRI HINKAN
			ON HINKAN.KAISHA_CD = @KAISHA_CD
			AND HINKAN.HINMOKU_SEQ = #tmp.HINMOKU_SEQ
		LEFT JOIN BC_MST_HINMOKU HINMOKU
			ON HINMOKU.KAISHA_CD = HINKAN.KAISHA_CD
			AND HINMOKU.HINMOKU_CD = HINKAN.HINMOKU_CD

		--�󒍓`�[���׊O��
		INSERT INTO HK_TBL_JUCHU_DTL_GAIKA
		(KAISHA_CD
		,JUCHU_NO
		,JUCHU_ENO
		,RATETYPE_CD
		,RATE
		,TUKA_TANKA
		,TUKA_KINGAKU
		,DEL_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD
			  ,DENPYO_NO
			  ,DENPYO_ENO
			  ,TORI_GAIKA.RATETYPE_CD
			  ,#tmp.RATE
			   --�a����o�ɁA�a���o�ɂ͒P��0
			  ,CASE WHEN #tmp.SHUKKO_KBN IN ('04', '06')
							THEN 0
					ELSE CONVERT(DECIMAL(14,4), #tmp.TORIHIKISAKI_TUKA_TANKA)
			   END
			   --�a����o�ɁA�a���o�ɂ͋��z0
			  ,CASE WHEN #tmp.SHUKKO_KBN IN ('04', '06')
							THEN 0
					ELSE dbo.CO_FUNC_HASU_SHORI_EX(#tmp.TORIHIKISAKI_TUKA_TANKA * SURYO ,'01' ,TUKA.DECIMAL_LENGTH)
			   END
			  ,0
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmp
		LEFT JOIN BC_MST_TORIHIKISAKI_GAIKA TORI_GAIKA
			ON TORI_GAIKA.KAISHA_CD = @KAISHA_CD
			AND TORI_GAIKA.TORIHIKISAKI_CD = #tmp.TOKUISAKI_CD
		LEFT JOIN BC_MST_TUKA TUKA
			ON TORI_GAIKA.KAISHA_CD = TUKA.KAISHA_CD
			AND TORI_GAIKA.TUKA_CD = TUKA.TUKA_CD
			AND TUKA.DEL_FLG = 0
			AND TUKA.MUKOU_FLG = 0

		--�󒍓`�[���׊g��
		INSERT INTO HK_TBL_JUCHU_DTL_EX
		(KAISHA_CD
		,JUCHU_NO
		,JUCHU_ENO
		,YOYAKU_DENPYO_NO
		,YOYAKU_DENPYO_ENO
		,SEIKYU_KIJUN_DATE
		,CHUMONSU
		,CHUMON_KINGAKU
		,CHUMON_LOT_NUM
		,CHUMON_BARA_NUM
		,KAKERITU_REF_KBN
		,HIKIATE_KBN
		,KANRYO_KBN
		,IDO_SAKI_SOKO_CD
		,JAN_SEAL_EXPORT_FLG
		,GEDAI_MACHI_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD
			  ,DENPYO_NO
			  ,DENPYO_ENO
			  ,CASE WHEN JUCHU_KBN IN ('01', '03')	--�\��`�[NO
						THEN #tmp.YOYAKU_DENPYO_NO
					ELSE NULL
			   END
			  ,CASE WHEN JUCHU_KBN IN ('01', '03')	--�\��`�[�}��
						THEN #tmp.YOYAKU_DENPYO_ENO
					ELSE NULL
			   END
			  ,CONVERT(DATE, DTL_SEIKYU_KIJUN_DATE)
			  ,(CONVERT(DECIMAL, ISNULL(LOT_NUM, 0)) * ISNULL(HIN.STD_IRISU, 0)) + CONVERT(DECIMAL, ISNULL(BARA_NUM, 0))
			   --�a����o�ɁA�a���o�ɂ͒������z0
			  ,CASE WHEN #tmp.SHUKKO_KBN IN ('04', '06')
							THEN 0
					WHEN  TORI_GAIKA.TUKA_CD = @TUKA_CD
					        THEN dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD
												,#tmp.TOKUISAKI_CD 
												,(((CONVERT(DECIMAL, ISNULL(LOT_NUM, 0)) * ISNULL(HIN.STD_IRISU, 0)) + CONVERT(DECIMAL, ISNULL(BARA_NUM, 0))) * JUCHU_TANKA)	 --�������z=������*�P��
												,1
												,0)
					ELSE
							--�O�݂̏ꍇ
							dbo.CO_FUNC_HASU_SHORI_EX(#tmp.TORIHIKISAKI_TUKA_TANKA * ((CONVERT(DECIMAL, ISNULL(LOT_NUM, 0)) * ISNULL(HIN.STD_IRISU, 0)) + CONVERT(DECIMAL, ISNULL(BARA_NUM, 0))) ,'01' ,TUKA.DECIMAL_LENGTH)
			   END 
			  ,LOT_NUM
			  ,BARA_NUM
			  ,KAKERITU_REF_KBN --�|���Q�Ƌ敪
			  ,HIKIATE_KBN		--�����敪
			  ,'01' --�����敪:�y���o�ׁz�Œ�
			  ,CASE WHEN JUCHU_KBN = '03'		--�ړ���q�ɃR�[�h
						THEN AZUKE_AZUKARI_IDO_SOKO_CD
					ELSE NULL
			   END
			  ,NULL	--JAN�V�[���o�̓t���O
			  ,0	--����҂��t���O
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmp
		LEFT JOIN BC_MST_HINMOKU_KANRI HINKAN
			ON HINKAN.KAISHA_CD = @KAISHA_CD
			AND HINKAN.HINMOKU_SEQ = #tmp.HINMOKU_SEQ
		LEFT JOIN BC_MST_HINMOKU HIN
			ON HIN.KAISHA_CD = HINKAN.KAISHA_CD
			AND HIN.HINMOKU_CD = HINKAN.HINMOKU_CD
		LEFT JOIN BC_MST_TORIHIKISAKI_GAIKA TORI_GAIKA
			ON TORI_GAIKA.KAISHA_CD = @KAISHA_CD
			AND TORI_GAIKA.TORIHIKISAKI_CD = #tmp.TOKUISAKI_CD
		LEFT JOIN BC_MST_TUKA TUKA
			ON TORI_GAIKA.KAISHA_CD = TUKA.KAISHA_CD
			AND TORI_GAIKA.TUKA_CD = TUKA.TUKA_CD
			AND TUKA.DEL_FLG = 0
			AND TUKA.MUKOU_FLG = 0
		
		--�o�ח\��
		INSERT INTO HK_TBL_SHUKKA_YOTEI
		(KAISHA_CD
		,SHUKKA_YOTEI_NO
		,JUCHU_NO
		,JUCHU_ENO
		,SHUKKO_KBN
		,WF_SHONIN_STATUS
		,NYUKA_YOTEI_NO
		,ZAIKO_SEQ
		,HINMOKU_SEQ
		,SHOHIN_LOT
		,SHUKKA_YOTEI_DATE
		,NOHIN_YOTEI_DATE
		,KENSHU_YOTEI_DATE
		,SHUKKASAKI_CD
		,JISSEKI_SURYO
		,SURYO
		,SHUKKO_SURYO
		,GOUKAKU_SURYO
		,FUGOUKAKU_SURYO
		,FUGOUKAKU_KBN
		,TEKIYO
		,KENPIN_STATUS
		,KAKUNIN_MOSIOKURI
		,KANRYO_FLG
		,KENPIN_DATE
		,SHUKKO_DATE
		,NOHIN_DATE
		,KENSHU_DATE
		,IRISU
		,HAKOSU
		,NISUGATA_RENBAN
		,SHISAN_KEIJO_END_DATE
		,JISSEKI_KINGAKU
		,KINGAKU
		,JISSEKI_SHOHIZEI
		,SHOHIZEI
		,TAX_RATE
		,SHUKKA_SHIJI_NO
		,TAISHOGAI_FLG
		,KEIJO_STD_KBN
		,URIAGE_NO
		,URIAGE_DTL_KEY
		,BUNNO_MOTO_NO
		,EDI_SEND_STATUS
		,BUNNO_FLG
		,MEMO
		,DEL_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD
			  --�`�[�ԍ� + 0����4���̘A��
			  ,DENPYO_NO + RIGHT('0000' + CONVERT(NVARCHAR, ROW_NUMBER() OVER(PARTITION BY #tmp.GROUP_KEY ORDER BY #tmp.LINE_NO)), 4)	--�o�ח\��NO
			  ,DENPYO_NO				--��NO
			  ,DENPYO_ENO				--�󒍎}��
			  ,#tmp.SHUKKO_KBN			--�o�ɋ敪
			  ,'01'						--WF���F���
			  ,CASE WHEN JUCHU_KBN IN ('01', '03') 	--���ח\��NO
						THEN shukka.NYUKA_YOTEI_NO
					ELSE NULL
			   END
			  ,shukka.ZAIKO_SEQ			--�݌�SEQ
			  ,shukka.HINMOKU_SEQ		--�i��SEQ
			  ,NULL						--���i���b�g
			  ,CONVERT(DATE, DTL_SHUKKA_YOTEI_DATE)	--�o�ח\���
			  ,CONVERT(DATE, DTL_SHITEI_NOHIN_DATE)	--�[�i�\���
			  ,NULL						--�����\���
			  ,DTL_SHUKKASAKI_CD		--�o�א�R�[�h
			  ,CASE WHEN HIN.ZAIKO_KANRI_FLG = 1	--���ѐ���
						THEN NULL
					ELSE shukka.SURYO
			   END
			  ,shukka.SURYO				--����
			  ,NULL						--�o�ɐ���
			  ,NULL						--���i����
			  ,NULL						--�s���i����
			  ,NULL						--�s���i�敪
			  ,NULL						--�E�v
			  ,NULL						--���i�X�e�[�^�X
			  ,NULL						--�m�F�\��
			  ,0						--�����t���O
			  ,CONVERT(DATE, DTL_SHITEI_NOHIN_DATE)	--���i��
			  ,NULL						--�o�ɓ�
			  ,CONVERT(DATE, DTL_SHITEI_NOHIN_DATE)	--�[�i��
			  ,NULL						--������
			  ,HIN.STD_IRISU			--����(�i�ڂ̕W������)
			  ,NULL						--����
			  ,NULL						--���p�A��
			  ,CONVERT(DATE, DTL_SHITEI_NOHIN_DATE)	--���Y�v��I����
			  --�a����o�ɁA�a���o�ɂ͎��ы��z0
			  ,CASE WHEN #tmp.SHUKKO_KBN IN ('04', '06')
							THEN 0
					ELSE dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, shukka.SURYO * #tmp.JUCHU_TANKA, 1, 0)
			   END
			  --�a����o�ɁA�a���o�ɂ͋��z0
			  ,CASE WHEN #tmp.SHUKKO_KBN IN ('04', '06')
							THEN 0
					ELSE dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, shukka.SURYO * #tmp.JUCHU_TANKA, 1, 0)	--���z
			   END
			  --�a����o�ɁA�a���o�ɂ͎��я����0
			  ,CASE WHEN #tmp.SHUKKO_KBN IN ('04', '06')
							THEN 0
					ELSE dbo.CO_FUNC_HASU_SHORI(shukka.SURYO * #tmp.JUCHU_TANKA * TAX_RATE, TORI.JUCHU_SHOHIZEI_HASU_KBN, 0)	--���я����
			   END
			  --�a����o�ɁA�a���o�ɂ͏����0
			  ,CASE WHEN #tmp.SHUKKO_KBN IN ('04', '06')
							THEN 0
					ELSE dbo.CO_FUNC_HASU_SHORI(shukka.SURYO * #tmp.JUCHU_TANKA * TAX_RATE, TORI.JUCHU_SHOHIZEI_HASU_KBN, 0)	--�����
			   END
			  ,TAX_RATE					--�ŗ�
			  ,NULL						--�o�׎w��NO
			  ,CASE WHEN HIN.ZAIKO_KANRI_FLG = 1	--�ΏۊO�t���O
						THEN 0
					ELSE 1
			   END
			   ,'01'					--�v���敪(�o�׊)
			   ,NULL					--����NO
			   ,NULL					--���㖾�טA��
			   ,NULL					--���[��NO
			   ,0						--EDI���M���
			   ,0						--���[�t���O
			   ,NULL					--����
			   ,0						--�폜�t���O
			   ,@NOW
			   ,@USER_ID
			   ,@PGM_CD
			   ,@NOW
			   ,@USER_ID
			   ,@PGM_CD
		FROM #tmpShukkaYotei shukka
		INNER JOIN #tmp
			ON #tmp.LINE_NO = shukka.LINE_NO
		LEFT JOIN BC_MST_HINMOKU_KANRI HINKAN
			ON HINKAN.KAISHA_CD = @KAISHA_CD
			AND HINKAN.HINMOKU_SEQ = #tmp.HINMOKU_SEQ
		LEFT JOIN BC_MST_HINMOKU HIN
			ON HIN.KAISHA_CD = HINKAN.KAISHA_CD
			AND HIN.HINMOKU_CD = HINKAN.HINMOKU_CD
		LEFT JOIN BC_MST_TORIHIKISAKI TORI
			ON TORI.KAISHA_CD = @KAISHA_CD
			AND TORI.TORIHIKISAKI_CD = #tmp.TOKUISAKI_CD

		--�o�ח\��O��
		INSERT INTO HK_TBL_SHUKKA_YOTEI_GAIKA
		(KAISHA_CD
		,SHUKKA_YOTEI_NO
		,JISSEKI_RATE
		,RATE
		,JISSEKI_TUKA_KINGAKU
		,TUKA_KINGAKU
		,DEL_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD
			  ,DENPYO_NO + RIGHT('0000' + CONVERT(NVARCHAR, ROW_NUMBER() OVER(PARTITION BY GROUP_KEY ORDER BY #tmp.LINE_NO)), 4)
			  ,#tmp.RATE
			  ,#tmp.RATE
			  --�a����o�ɁA�a���o�ɂ͋��z0
			  ,CASE WHEN #tmp.SHUKKO_KBN IN ('04', '06')
							THEN 0
					ELSE CASE WHEN CONVERT(DECIMAL(7, 3),#tmp.RATE) = 1 THEN dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, shukka.SURYO * #tmp.JUCHU_TANKA, 1, 0)
					     ELSE dbo.CO_FUNC_HASU_SHORI_EX(#tmp.TORIHIKISAKI_TUKA_TANKA * shukka.SURYO ,'01' ,TUKA.DECIMAL_LENGTH) 
					END
			   END
			   --�a����o�ɁA�a���o�ɂ͋��z0
			  ,CASE WHEN #tmp.SHUKKO_KBN IN ('04', '06')
							THEN 0
					ELSE CASE WHEN CONVERT(DECIMAL(7, 3),#tmp.RATE) = 1 THEN dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, shukka.SURYO * #tmp.JUCHU_TANKA, 1, 0)
					     ELSE dbo.CO_FUNC_HASU_SHORI_EX(#tmp.TORIHIKISAKI_TUKA_TANKA * shukka.SURYO ,'01' ,TUKA.DECIMAL_LENGTH) 
					END
			   END
			  ,0
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmpShukkaYotei shukka
		INNER JOIN #tmp
			ON #tmp.LINE_NO = shukka.LINE_NO
		LEFT JOIN BC_MST_TORIHIKISAKI_GAIKA TORI_GAIKA
			ON TORI_GAIKA.KAISHA_CD = @KAISHA_CD
			AND TORI_GAIKA.TORIHIKISAKI_CD = #tmp.TOKUISAKI_CD
		LEFT JOIN BC_MST_TUKA TUKA
			ON TORI_GAIKA.KAISHA_CD = TUKA.KAISHA_CD
			AND TORI_GAIKA.TUKA_CD = TUKA.TUKA_CD
			AND TUKA.DEL_FLG = 0
			AND TUKA.MUKOU_FLG = 0

		--�o�ח\��g��
		INSERT INTO HK_TBL_SHUKKA_YOTEI_EX
		(KAISHA_CD
		,SHUKKA_YOTEI_NO
		,YOYAKU_DENPYO_NO
		,YOYAKU_DENPYO_ENO
		,SHUKKA_JISSEKIZUMI_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD
			  ,DENPYO_NO + RIGHT('0000' + CONVERT(NVARCHAR, ROW_NUMBER() OVER(PARTITION BY GROUP_KEY ORDER BY #tmp.LINE_NO)), 4)
			  ,CASE WHEN JUCHU_KBN IN ('01', '03')	--�\��`�[NO
						THEN shukka.YOYAKU_JUCHU_NO
					ELSE NULL
			   END
			  ,CASE WHEN JUCHU_KBN IN ('01', '03')	--�\��`�[�}��
						THEN shukka.YOYAKU_JUCHU_ENO
					ELSE NULL
			   END
			  ,0
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmpShukkaYotei shukka
		INNER JOIN #tmp
			ON #tmp.LINE_NO = shukka.LINE_NO

		/***********�q�Ɉړ����̔������A�q�Ɉړ����쐬START***********/
		--�����ԍ��̍̔ԁA�Ɉړ�NO�̍̔Ԃ����s����

		--�q�Ɉړ��̔ԗp�ɕϐ��ǉ�
		DECLARE @KETA_SOKO		DECIMAL(2,0)
		DECLARE @GET_NO_S_SOKO	DECIMAL(10,0) 
		DECLARE @GET_NO_E_SOKO	DECIMAL(10,0)
		DECLARE @RET_STATUS_SOKO INT

		--�̔Ԑ����擾
		SELECT @INS_CNT = COUNT(*)
		FROM #tmpHdr
		WHERE #tmpHdr.JUCHU_KBN = '03'

		--�X�g�A�h�v���V�[�W���[�uGET_NEXT_SAIBAN�v���ďo���A�����ԍ����擾����
		EXEC @RET_STATUS = GET_NEXT_SAIBAN @KAISHA_CD
											,'KBHC'
											,'@NONPREFIX@'
											,@INS_CNT
											,@USER_ID
											,@PGM_CD
											,@KETA OUTPUT
											,@GET_NO_S OUTPUT
											,@GET_NO_E OUTPUT
			
		--�߂�l��0�ȊO�̏ꍇ�͍̔Ԏ��s
		IF(@RET_STATUS <> 0)
		BEGIN
			--�ϐ����^�[���R�[�h��3��ݒ肵
			SET @RetCd = 3
			--�I�������ɃW�����v
			GOTO END_PROC
		END

		--�X�g�A�h�v���V�[�W���[�uGET_NEXT_SAIBAN�v���ďo���A�q�Ɉړ��ԍ����擾����
		EXEC @RET_STATUS_SOKO = GET_NEXT_SAIBAN @KAISHA_CD
											,'ZKSI'
											,'@NONPREFIX@'
											,@INS_CNT
											,@USER_ID
											,@PGM_CD
											,@KETA_SOKO OUTPUT
											,@GET_NO_S_SOKO OUTPUT
											,@GET_NO_E_SOKO OUTPUT
			
		--�߂�l��0�ȊO�̏ꍇ�͍̔Ԏ��s
		IF(@RET_STATUS_SOKO <> 0)
		BEGIN
			--�ϐ����^�[���R�[�h��3��ݒ肵
			SET @RetCd = 4
			--�I�������ɃW�����v
			GOTO END_PROC
		END

		--#tmpHdr�ɔ����ԍ��E�q�Ɉړ�NO��ݒ肷��
		--�����ԍ��FRIGHT(@KETA����0���� + @GET_NO_S(�̔ԊJ�n�ԍ�) + #tmpHdr�s�ԍ� - 1), @KETA)
		--�q�Ɉړ��ԍ����FRIGHT(@KETA_SOKO����0���� + @GET_NO_S_SOKO(�̔ԊJ�n�ԍ�) + #tmpHdr�s�ԍ� - 1), @KETA_SOKO)
		UPDATE #tmpHdr
		SET HACCHU_NO = #tmpHdrNo.HACCHU_NO
			,SOKO_IDO_NO = #tmpHdrNo.SOKO_IDO_NO
		FROM #tmpHdr
		INNER JOIN (SELECT GROUP_KEY
							,RIGHT(REPLICATE('0', @KETA)  + CONVERT(NVARCHAR, (@GET_NO_S + ROW_NUMBER() OVER (ORDER BY GROUP_KEY) -1)) , @KETA) AS HACCHU_NO
							,RIGHT(REPLICATE('0', @KETA_SOKO)  + CONVERT(NVARCHAR, (@GET_NO_S_SOKO + ROW_NUMBER() OVER (ORDER BY GROUP_KEY) -1)) , @KETA_SOKO) AS SOKO_IDO_NO
					FROM #tmpHdr
					WHERE JUCHU_KBN = '03'
					) #tmpHdrNo
			ON #tmpHdr.GROUP_KEY = #tmpHdrNo.GROUP_KEY

		--#tmpHdr�ɑq�Ɉړ��ԍ���ݒ肷��
		--�q�Ɉړ��ԍ����FRIGHT(@KETA����0���� + @GET_NO_S(�̔ԊJ�n�ԍ�) + #tmpHdr�s�ԍ� - 1), @KETA)
		UPDATE #tmpHdr
		SET SOKO_IDO_NO = #tmpHdrNo.SOKO_IDO_NO
		FROM #tmpHdr
		INNER JOIN (SELECT GROUP_KEY
							,RIGHT(REPLICATE('0', @KETA)  + CONVERT(NVARCHAR, (@GET_NO_S + ROW_NUMBER() OVER (ORDER BY GROUP_KEY) -1)) , @KETA) AS SOKO_IDO_NO
					FROM #tmpHdr
					WHERE JUCHU_KBN = '03'
					) #tmpHdrNo
			ON #tmpHdr.GROUP_KEY = #tmpHdrNo.GROUP_KEY

		--�ϐ��̏�����
		SET @INS_CNT = NULL
		SET @KETA = NULL
		SET @GET_NO_S = NULL 
		SET @GET_NO_E = NULL
		SET @RET_STATUS = NULL
		SET @KETA_SOKO = NULL
		SET @GET_NO_S_SOKO = NULL
		SET @GET_NO_E_SOKO = NULL
		SET @RET_STATUS_SOKO = NULL
		/***********�����ԍ��E�q�Ɉړ�NO�̔ԏ���END***********/

		--�����`�[�w�b�_
		INSERT INTO KB_TBL_HACCHU_HDR
		(KAISHA_CD
		,HACCHU_NO
		,KAKUTEI_KBN
		,WF_SHONIN_STATUS
		,HACCHU_DATE
		,SHIRESAKI_CD
		,SHIRESAKI_TANTOSHA_NM
		,TANTO_BUSHO_CD
		,TANTOSHA_CD
		,PROJECT_CD
		,TEKIYO
		,SHIHARAISAKI_CD
		,SHIHARAI_HOHO_PATTERN
		,SHIHARAI_DATE
		,SHUKKASAKI_CD
		,NYUKA_YOTEI_DATE
		,NYUKO_KBN
		,UCHIZEI_SOTOZEI_KBN
		,SHOHIZEI_KBN
		,HENPIN_MOTO_URIAGE_NO
		,JIDO_HACCHU_FLG
		,IKKATSU_HIKIATE_FLG
		,HDR_JIDO_BUNNO_FLG
		,CANCEL_FLG
		,CANCEL_RIYU
		,CANCEL_TM
		,EDI_FLG
		,EDI_SEND_STATUS
		,DEL_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD			--��ЃR�[�h
			  ,HACCHU_NO			--����NO
			  ,NULL					--����m��敪
			  ,'01'					--WF���F���
			  ,CONVERT(DATE, JUCHU_DATE)			--������
			  ,NULL					--�d����R�[�h
			  ,NULL					--�d����S���Җ�
			  ,TANTO_BUSHO_CD		--�S�������R�[�h
			  ,TANTOSHA_CD			--�S���҃R�[�h
			  ,NULL					--�v���W�F�N�g�R�[�h
			  ,'�q�Ɉړ�'			--�E�v
			  ,NULL					--�x����R�[�h
			  ,NULL					--�x�����@�p�^�[��
			  ,NULL					--�x����
			  ,NULL					--�o�א�R�[�h
			  ,CONVERT(DATE, SHITEI_NOHIN_DATE)	--���ח\���
			  ,'40'					--���ɋ敪�F�q�Ɉړ�
			  ,'01'					--���ŊO�ŋ敪
			  ,NULL					--����ŋ敪
			  ,NULL					--�ԕi������NO
			  ,0					--���������t���O
			  ,0					--�ꊇ�����t���O
			  ,0					--�������[�t���O
			  ,0					--�������t���O
			  ,NULL					--���������R
			  ,NULL					--����������
			  ,0					--EDI�t���O	
			  ,0					--EDI���M���
			  ,0					--�폜�t���O
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmpHdr
		WHERE #tmpHdr.JUCHU_KBN = '03'

		--�����`�[�w�b�_�O��
		INSERT INTO KB_TBL_HACCHU_HDR_GAIKA
		(KAISHA_CD
		,HACCHU_NO
		,TUKA_CD
		,DEL_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD
			  ,HACCHU_NO
			  ,TORIHIKI.TUKA_CD
			  ,0
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmpHdr HDR
		LEFT JOIN BC_MST_TORIHIKISAKI_GAIKA TORIHIKI
			ON TORIHIKI.KAISHA_CD = @KAISHA_CD
			AND TORIHIKI.TORIHIKISAKI_CD = HDR.TOKUISAKI_CD
		WHERE HDR.JUCHU_KBN = '03'

		--�����`�[�w�b�_�g��
		INSERT INTO KB_TBL_HACCHU_HDR_EX
		(KAISHA_CD
		,HACCHU_NO
		,SHOKAI_REPEAT_KBN
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD
			  ,HACCHU_NO
			  ,NULL
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmpHdr
		WHERE #tmpHdr.JUCHU_KBN = '03'

		--�����`�[����
		INSERT INTO KB_TBL_HACCHU_DTL
		(KAISHA_CD
		,HACCHU_NO
		,HACCHU_ENO
		,SHIRE_KBN
		,HINMOKU_SEQ
		,SHUKKASAKI_CD
		,SOKO_CD
		,SHOHIN_LOT
		,NYUKA_YOTEI_DATE
		,NYUKA_YOTEI_JI_KBN
		,KENSHU_YOTEI_DATE
		,IRISU
		,HAKOSU
		,NISUGATA_RENBAN
		,SURYO
		,TANKA
		,STD_TANKA
		,TANKA_KAKERITSU
		,KINGAKU
		,SHOHIZEI
		,TAX_RATE
		,KAZEI_KBN
		,KEIJO_STD_KBN
		,TEKIYO
		,BIKO
		,SHOKUTI_HINMOKU_NM
		,GTIN
		,GTIN_KBN_CD
		,TAX_SITEI_KBN
		,JIDO_BUNNO_FLG
		,DEL_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD						--��ЃR�[�h
			  ,#tmpHdr.HACCHU_NO				--����NO
			  ,ROW_NUMBER() OVER(PARTITION BY #tmp.GROUP_KEY ORDER BY #tmp.LINE_NO)	--�}��
			  ,'01'								--�d���敪
			  ,#tmp.HINMOKU_SEQ					--�i��SEQ	
			  ,NULL								--�o�א�R�[�h
			  ,#tmp.AZUKE_AZUKARI_IDO_SOKO_CD	--�q�ɃR�[�h(�ړ���)
			  ,NULL								--���i���b�g
			  ,CONVERT(DATE,#tmp.DTL_SHITEI_NOHIN_DATE)			--���ח\���
			  ,NULL								--���ח\�莞�敪
			  ,NULL								--�����\���
			  ,NULL								--����
			  ,NULL								--����
			  ,NULL								--���p�A��
			  ,SURYO							--����
			  ,JUCHU_TANKA						--�P��
			  ,TANKA.SOTOZEI_KONYU_TANKA		--�W���P��
			  ,NULL								--�P���|��
			  ,dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, JUCHU_TANKA * SURYO, 1, 0)				--���z
			  ,dbo.CO_FUNC_HASU_SHORI((JUCHU_TANKA * SURYO) * TAX_RATE, TORI.JUCHU_SHOHIZEI_HASU_KBN, 0)	--�����
			  ,TAX_RATE							--�ŗ�
			  ,KAZEI_KBN						--�ېŋ敪
			  ,'01'								--�v���敪�F���׊
			  ,'�q�Ɉړ�'						--�E�v
			  ,DTL_BIKO							--���l
			  ,NULL								--�����i�ږ�
			  ,NULL								--GTIN
			  ,NULL								--GTIN�敪�R�[�h
			  ,TAX_SITEI_KBN					--�ŗ��w��敪
			  ,0								--�������[�t���O
			  ,0								--�폜�t���O
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmp
		LEFT JOIN #tmpHdr
			ON #tmp.GROUP_KEY = #tmpHdr.GROUP_KEY
		LEFT JOIN BC_MST_TANKA TANKA 
			ON TANKA.KAISHA_CD = @KAISHA_CD
			AND TANKA.HINMOKU_SEQ = #tmp.HINMOKU_SEQ
			AND DATEDIFF(DAY, START_DATE, #tmp.DTL_SHUKKA_YOTEI_DATE) >= 0
			AND DATEDIFF(DAY, END_DATE, #tmp.DTL_SHUKKA_YOTEI_DATE) <= 0
		LEFT JOIN BC_MST_TORIHIKISAKI TORI
			ON TORI.KAISHA_CD = @KAISHA_CD
			AND TORI.TORIHIKISAKI_CD = #tmp.TOKUISAKI_CD
		WHERE #tmp.JUCHU_KBN = '03'

		--�����`�[���׊O��
		INSERT INTO KB_TBL_HACCHU_DTL_GAIKA
		(KAISHA_CD
		,HACCHU_NO
		,HACCHU_ENO
		,RATETYPE_CD
		,RATE
		,TUKA_TANKA
		,TUKA_KINGAKU
		,DEL_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD
			  ,#tmpHdr.HACCHU_NO
			  ,ROW_NUMBER() OVER(PARTITION BY #tmp.GROUP_KEY ORDER BY #tmp.LINE_NO)
			  ,TORI_GAIKA.RATETYPE_CD
			  ,#tmp.RATE
			  ,TORIHIKISAKI_TUKA_TANKA
			  ,dbo.CO_FUNC_HASU_SHORI_EX(#tmp.TORIHIKISAKI_TUKA_TANKA * SURYO ,'01' ,TUKA.DECIMAL_LENGTH)
			  ,0
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmp
		LEFT JOIN #tmpHdr
			ON #tmp.GROUP_KEY = #tmpHdr.GROUP_KEY
		LEFT JOIN BC_MST_TORIHIKISAKI_GAIKA TORI_GAIKA
			ON TORI_GAIKA.KAISHA_CD = @KAISHA_CD
			AND TORI_GAIKA.TORIHIKISAKI_CD = #tmp.TOKUISAKI_CD
		LEFT JOIN BC_MST_TUKA TUKA
			ON TORI_GAIKA.KAISHA_CD = TUKA.KAISHA_CD
			AND TORI_GAIKA.TUKA_CD = TUKA.TUKA_CD
			AND TUKA.DEL_FLG = 0
			AND TUKA.MUKOU_FLG = 0
		WHERE #tmp.JUCHU_KBN = '03'

		--�����`�[���׊g��
		INSERT INTO KB_TBL_HACCHU_DTL_EX
		(KAISHA_CD
		,HACCHU_NO
		,HACCHU_ENO
		,UNSO_KBN
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD
			  ,#tmpHdr.HACCHU_NO
			  ,ROW_NUMBER() OVER(PARTITION BY #tmp.GROUP_KEY ORDER BY #tmp.LINE_NO)
			  ,NULL
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmp
		LEFT JOIN #tmpHdr
			ON #tmp.GROUP_KEY = #tmpHdr.GROUP_KEY
		WHERE #tmp.JUCHU_KBN = '03'

		--���ח\��
		INSERT INTO KB_TBL_NYUKA_YOTEI
		(KAISHA_CD
		,NYUKA_YOTEI_NO
		,HACCHU_NO
		,HACCHU_ENO
		,IDO_NO
		,NYUKO_KBN
		,WF_SHONIN_STATUS
		,HINMOKU_SEQ
		,SHOHIN_LOT
		,NYUKA_YOTEI_DATE
		,KENSHU_YOTEI_DATE
		,IRISU
		,HAKOSU
		,NISUGATA_RENBAN
		,SOKO_CD
		,SHUKKASAKI_CD
		,JISSEKI_SURYO
		,SURYO
		,NYUKA_SURYO
		,GOUKAKU_SURYO
		,FUGOUKAKU_SURYO
		,FUGOUKAKU_KBN
		,TEKIYO
		,KENPIN_STATUS
		,KAKUNIN_MOSIOKURI
		,KENPIN_DATE
		,NYUKO_DATE
		,KENSHU_DATE
		,SHISAN_KEIJO_START_DATE
		,JISSEKI_KINGAKU
		,KINGAKU
		,JISSEKI_SHOHIZEI
		,SHOHIZEI
		,TAX_RATE
		,NYUKA_SHIJI_NO
		,TAISHOGAI_FLG
		,KEIJO_STD_KBN
		,SHIRE_NO
		,SHIRE_DTL_KEY
		,BUNNO_MOTO_NO
		,NYUKA_YOTEI_JI_KBN
		,EDI_SEND_STATUS
		,BUNNO_FLG
		,MEMO
		,BUNNO_NYUKA_YOTEI_DATE
		,DEL_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD				--��ЃR�[�h
			  ,#tmpHdr.HACCHU_NO + RIGHT('0000' + CONVERT(NVARCHAR, ROW_NUMBER() OVER(PARTITION BY #tmp.GROUP_KEY ORDER BY #tmp.LINE_NO)), 4)
			  ,#tmpHdr.HACCHU_NO		--����NO
			  ,ROW_NUMBER() OVER(PARTITION BY #tmp.GROUP_KEY ORDER BY #tmp.LINE_NO)	--�}��
			  ,NULL						--�ړ�NO
			  ,'40'						--���ɋ敪�F�q�Ɉړ�
			  ,'01'						--WF���F���
			  ,shukka.HINMOKU_SEQ		--�i��SEQ
			  ,NULL						--���i���b�g
			  ,CASE 					--���ח\���
			  		WHEN #tmp.DTL_SHITEI_NOHIN_DATE IS NOT NULL
			  			THEN CONVERT(DATE, #tmp.DTL_SHITEI_NOHIN_DATE)
			  			ELSE CONVERT(DATE, #tmp.DTL_SHUKKA_YOTEI_DATE)
			  	END
			  ,NULL						--�����\���
			  ,NULL						--����
			  ,NULL						--����
			  ,NULL						--���p�A��
			  ,#tmp.AZUKE_AZUKARI_IDO_SOKO_CD	--�q�ɃR�[�h(�ړ���)
			  ,NULL						--�o�א�R�[�h
			  ,CASE WHEN HIN.ZAIKO_KANRI_FLG = 1	--���ѐ���
						THEN NULL
					ELSE shukka.SURYO
			   END
			  ,shukka.SURYO				--����
			  ,NULL						--���א���
			  ,NULL						--���i����
			  ,NULL						--�s���i����
			  ,NULL						--�s���i�敪
			  ,NULL						--�E�v
			  ,'010'					--���i�X�e�[�^�X(������)
			  ,NULL						--�m�F�\������
			  ,NULL						--���i��
			  ,NULL						--���ɓ�
			  ,NULL						--������
			  ,CONVERT(DATE, #tmp.DTL_SHITEI_NOHIN_DATE)	--���Y�v��J�n��(�A�h�I���ŕi�ڂ̊J�n�����͂Ȃ��Ȃ�)
			  ,dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, JUCHU_TANKA * shukka.SURYO, 1, 0)	--���ы��z
			  ,dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, JUCHU_TANKA * shukka.SURYO, 1, 0)	--���z
			  ,dbo.CO_FUNC_HASU_SHORI((JUCHU_TANKA * shukka.SURYO) * TAX_RATE, TORI.JUCHU_SHOHIZEI_HASU_KBN, 0)		--���я����
			  ,dbo.CO_FUNC_HASU_SHORI((JUCHU_TANKA * shukka.SURYO) * TAX_RATE, TORI.JUCHU_SHOHIZEI_HASU_KBN, 0)		--�����
			  ,TAX_RATE					--�ŗ�
			  ,NULL						--���׎w��NO
			  ,CASE WHEN HIN.ZAIKO_KANRI_FLG = 1	--�ΏۊO�t���O
						THEN 0
					ELSE 1
			   END
			  ,'01'						--�v���敪(���׊)
			  ,NULL						--�d��NO
			  ,NULL						--�d�����טA��
			  ,NULL						--���[��NO
			  ,NULL						--���ח\�莞�敪
			  ,0						--EDI���M���
			  ,0						--���[�t���O
			  ,NULL						--����
			  ,NULL						--���[���ח\���
			  ,0						--�폜�t���O
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmpShukkaYotei shukka
		INNER JOIN #tmp
			ON #tmp.LINE_NO = shukka.LINE_NO
		LEFT JOIN #tmpHdr
			ON #tmp.GROUP_KEY = #tmpHdr.GROUP_KEY
		LEFT JOIN BC_MST_HINMOKU_KANRI HINKAN
			ON HINKAN.KAISHA_CD = @KAISHA_CD
			AND HINKAN.HINMOKU_SEQ = shukka.HINMOKU_SEQ
		LEFT JOIN BC_MST_HINMOKU HIN
			ON HIN.KAISHA_CD = HINKAN.KAISHA_CD
			AND HIN.HINMOKU_CD = HINKAN.HINMOKU_CD
		LEFT JOIN BC_MST_TORIHIKISAKI TORI
			ON TORI.KAISHA_CD = @KAISHA_CD
			AND TORI.TORIHIKISAKI_CD = #tmp.TOKUISAKI_CD
		WHERE #tmp.JUCHU_KBN = '03'

		--���ח\��O��
		INSERT INTO KB_TBL_NYUKA_YOTEI_GAIKA
		(KAISHA_CD
		,NYUKA_YOTEI_NO
		,JISSEKI_RATE
		,RATE
		,JISSEKI_TUKA_KINGAKU
		,TUKA_KINGAKU
		,DEL_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT  @KAISHA_CD
			   ,#tmpHdr.HACCHU_NO + RIGHT('0000' + CONVERT(NVARCHAR, ROW_NUMBER() OVER(PARTITION BY #tmp.GROUP_KEY ORDER BY #tmp.LINE_NO)), 4)
			   ,#tmp.RATE
			   ,#tmp.RATE
			   ,dbo.CO_FUNC_HASU_SHORI_EX(#tmp.TORIHIKISAKI_TUKA_TANKA * shukka.SURYO ,'01' ,TUKA.DECIMAL_LENGTH)
			   ,dbo.CO_FUNC_HASU_SHORI_EX(#tmp.TORIHIKISAKI_TUKA_TANKA * shukka.SURYO ,'01' ,TUKA.DECIMAL_LENGTH)
			   ,0
			   ,@NOW
			   ,@USER_ID
			   ,@PGM_CD
			   ,@NOW
			   ,@USER_ID
			   ,@PGM_CD
		FROM #tmpShukkaYotei shukka
		INNER JOIN #tmp
			ON #tmp.LINE_NO = shukka.LINE_NO
		LEFT JOIN #tmpHdr
			ON #tmp.GROUP_KEY = #tmpHdr.GROUP_KEY
		LEFT JOIN BC_MST_TORIHIKISAKI_GAIKA TORI_GAIKA
			ON TORI_GAIKA.KAISHA_CD = @KAISHA_CD
			AND TORI_GAIKA.TORIHIKISAKI_CD = #tmp.TOKUISAKI_CD
		LEFT JOIN BC_MST_TUKA TUKA
			ON TORI_GAIKA.KAISHA_CD = TUKA.KAISHA_CD
			AND TORI_GAIKA.TUKA_CD = TUKA.TUKA_CD
			AND TUKA.DEL_FLG = 0
			AND TUKA.MUKOU_FLG = 0
		WHERE #tmp.JUCHU_KBN = '03'

		--�q�Ɉړ��w�b�_
		INSERT INTO ZK_TBL_SOKO_IDO_HDR
		(KAISHA_CD
		,SOKO_IDO_NO
		,SOKO_IDO_DATE
		,JUCHU_NO
		,SHUKKA_SHIJI_NO
		,HACCHU_NO
		,NYUKA_SHIJI_NO
		,TEKIYO
		,CANCEL_FLG
		,CANCEL_RIYU
		,CANCEL_TM
		,DEL_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD
			  ,SOKO_IDO_NO
			  ,CONVERT(DATE, JUCHU_DATE)	--�q�Ɉړ���=�󒍓��Ƃ���
			  ,DENPYO_NO
			  ,NULL
			  ,HACCHU_NO
			  ,NULL
			  ,NULL
			  ,0
			  ,NULL
			  ,NULL
			  ,0
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmpHdr
		WHERE #tmpHdr.JUCHU_KBN = '03'

		--�q�Ɉړ�����
		INSERT INTO ZK_TBL_SOKO_IDO_DTL
		(KAISHA_CD
		,SOKO_IDO_NO
		,SOKO_IDO_ENO
		,SHUKKA_YOTEI_NO
		,NYUKA_YOTEI_NO
		,HINMOKU_SEQ
		,IDO_SURYO
		,BIKO
		,DEL_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD
			  ,#tmpHdr.SOKO_IDO_NO
			  ,ROW_NUMBER() OVER(PARTITION BY #tmp.GROUP_KEY ORDER BY #tmp.LINE_NO)
			  ,#tmp.DENPYO_NO + RIGHT('0000' + CONVERT(NVARCHAR, ROW_NUMBER() OVER(PARTITION BY #tmp.GROUP_KEY ORDER BY #tmp.LINE_NO)), 4)
			  ,#tmpHdr.HACCHU_NO + RIGHT('0000' + CONVERT(NVARCHAR, ROW_NUMBER() OVER(PARTITION BY #tmp.GROUP_KEY ORDER BY #tmp.LINE_NO)), 4)
			  ,#tmp.HINMOKU_SEQ
			  ,shukka.SURYO		--�ړ�����
			  ,NULL
			  ,0
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmpShukkaYotei shukka
		INNER JOIN #tmp
			ON #tmp.LINE_NO = shukka.LINE_NO
		LEFT JOIN #tmpHdr
			ON #tmp.GROUP_KEY = #tmpHdr.GROUP_KEY
		WHERE #tmp.JUCHU_KBN = '03'

		--�ꊇ�捞�ł͏o�׎w���E���׎w���͖��w���̂��ߍ쐬���Ȃ�
		/***********�q�Ɉړ����̔������A�q�Ɉړ����쐬END***********/
		/*===============================�o�^����END===============================*/

		SELECT @RetCd

		--�o�^�\�̏ꍇ�A�G���[�s�Ȃ�(�󃌃R�[�h)�Ƃ��ĕԂ�
		SELECT 0
		WHERE 1 = 0

		--�x�����R�[�h�쐬
		--�G���[���b�Z�[�W���g�p����
		--�����������Z�o����鐿�����ɂ�����
		--������ɑ΂��鐿���e�[�u���̐��������ߋ��̏ꍇ�͌x���Ώ�
		UPDATE #tmp
		SET ERROR_MSG = @ALERT_MSG_SEIKYU + DTL.JUCHU_NO + '-' + CONVERT(NVARCHAR, DTL.JUCHU_ENO)
		FROM #tmp
		LEFT JOIN HK_TBL_JUCHU_DTL DTL
			ON DTL.KAISHA_CD = @KAISHA_CD
			AND #tmp.DENPYO_NO = DTL.JUCHU_NO
		LEFT JOIN HK_TBL_JUCHU_HDR HDR
			ON HDR.KAISHA_CD = DTL.KAISHA_CD
			AND HDR.JUCHU_NO = DTL.JUCHU_NO
		WHERE JUCHU_KBN = '01'
		AND ERROR_MSG IS NULL
		AND ( EXISTS (SELECT *
		            FROM SK_TBL_SEIKYU_SHIME SEIKYU
					WHERE SEIKYU.KAISHA_CD = @KAISHA_CD
					AND SEIKYU.SEIKYUSAKI_CD = HDR.SEIKYUSAKI_CD
					AND DATEDIFF(DAY, SEIKYU.SEIKYU_DATE, dbo.HK_FUNC_GET_SEIKYU_DATE_PATTERN(@KAISHA_CD, HDR.SEIKYUSAKI_CD, HDR.KAISHU_HOHO_PATTERN, #tmp.DTL_SEIKYU_KIJUN_DATE)) <= 0
					AND SEIKYU.CANCEL_FLG = 0
					AND SEIKYU.DEL_FLG = 0
					)
			OR EXISTS (SELECT *
		            FROM SK_TBL_SEIKYU_HDR SEIKYU
					WHERE SEIKYU.KAISHA_CD = @KAISHA_CD
					AND SEIKYU.SEIKYUSAKI_CD = HDR.SEIKYUSAKI_CD
					AND DATEDIFF(DAY, SEIKYU.SEIKYU_DATE, dbo.HK_FUNC_GET_SEIKYU_DATE_PATTERN(@KAISHA_CD, HDR.SEIKYUSAKI_CD, HDR.KAISHU_HOHO_PATTERN, #tmp.DTL_SEIKYU_KIJUN_DATE)) <= 0
					AND SEIKYU.CANCEL_FLG = 0
					AND SEIKYU.DEL_FLG = 0
					)
			)

		--�{�󒍂̓`�[�ɂ����āA�o�ח\�肪�x���̏ꍇ�͌x���Ώ�
		UPDATE #tmp
		SET ERROR_MSG = @ALERT_MSG_HOLIDAY + DTL.JUCHU_NO + '-' + CONVERT(NVARCHAR, DTL.JUCHU_ENO)
		FROM #tmp
		LEFT JOIN HK_TBL_JUCHU_DTL DTL
			ON #tmp.DENPYO_NO = DTL.JUCHU_NO
		WHERE dbo.CO_FUNC_IS_HOLIDAY_EX(@KAISHA_CD, DTL.SHUKKA_YOTEI_DATE) = 1
		AND JUCHU_KBN = '01'
		AND ERROR_MSG IS NULL

		--�o�ג�~���ԓ��̏ꍇ�͌x���Ώ�
		/**********************************************
	    *�o�ג�~���ԃ`�F�b�NSTART
	    **********************************************/
		UPDATE #tmp
	    SET #tmp.ERROR_MSG = 
				CASE --�o�ג�~����FROM <= �o�ח\���
					 WHEN HINMOKU.SYUKKA_TEISHI_KIKAN_FROM IS NOT NULL
							AND HINMOKU.SYUKKA_TEISHI_KIKAN_TO IS NULL
							AND DATEDIFF(DAY, HINMOKU.SYUKKA_TEISHI_KIKAN_FROM, DTL_SHUKKA_YOTEI_DATE) >= 0	
						THEN @ERR_MSG_CANNOT_USE_HINMOKU + @FLD_NM_DTL_SHUKKA_YOTEI_DATE
					 --�o�ג�~����TO >= �o�ח\���
					 WHEN HINMOKU.SYUKKA_TEISHI_KIKAN_FROM IS NULL
							AND HINMOKU.SYUKKA_TEISHI_KIKAN_TO IS NOT NULL
							AND DATEDIFF(DAY, HINMOKU.SYUKKA_TEISHI_KIKAN_TO, DTL_SHUKKA_YOTEI_DATE) <= 0
						THEN @ERR_MSG_CANNOT_USE_HINMOKU + @FLD_NM_DTL_SHUKKA_YOTEI_DATE
					 --�o�ג�~����FROM <= �o�ח\��� <= �o�ג�~����TO
					 WHEN HINMOKU.SYUKKA_TEISHI_KIKAN_FROM IS NOT NULL
							AND HINMOKU.SYUKKA_TEISHI_KIKAN_TO IS NOT NULL
							AND DATEDIFF(DAY, HINMOKU.SYUKKA_TEISHI_KIKAN_FROM, DTL_SHUKKA_YOTEI_DATE) >= 0
							AND DATEDIFF(DAY, HINMOKU.SYUKKA_TEISHI_KIKAN_TO, DTL_SHUKKA_YOTEI_DATE) <= 0
						THEN @ERR_MSG_CANNOT_USE_HINMOKU + @FLD_NM_DTL_SHUKKA_YOTEI_DATE
				END
		FROM #tmp
		INNER JOIN BC_MST_HINMOKU_KANRI HINKAN
			ON #tmp.HINMOKU_SEQ = HINKAN.HINMOKU_SEQ
		INNER JOIN BC_MST_HINMOKU_EX HINMOKU
			ON HINMOKU.KAISHA_CD = HINKAN.KAISHA_CD
			AND HINMOKU.HINMOKU_CD = HINKAN.HINMOKU_CD
		WHERE #tmp.ERROR_MSG IS NULL
		AND HINKAN.KAISHA_CD = @KAISHA_CD
		AND #tmp.JUCHU_KBN = '01'
		AND #tmp.SURYO > 0
		/**********************************************
	    *�o�ג�~���ԃ`�F�b�NEND
	    **********************************************/
	    
		--�x�����R�[�h�擾
		SELECT LINE_NO
			  ,ERROR_MSG
		FROM #tmp
		WHERE #tmp.ERROR_MSG IS NOT NULL
		ORDER BY LINE_NO

		--�o�^�`�[NO�擾
		SELECT COUNT(*)
			  ,MIN(DENPYO_NO) AS MIN_DENPYO_NO
			  ,MAX(DENPYO_NO) AS MAX_DENPYO_NO
		FROM #tmpHdr
		
		--�o�^�����`�[No�A����No�擾
		IF (@PGM_CD = 'EDITorikomiTool')
		BEGIN
			SELECT 
				DENPYO_NO
				,DENPYO_ENO
			FROM #tmp
			WHERE 
				HINMOKU NOT IN ('DAIBIKI' ,'DELI', 'CHARGE-TF', 'CHARGE')
			ORDER BY
				DENPYO_NO
				,DENPYO_ENO
		 END
	END

	--#tmp�A#tmpHdr���폜����
    DROP TABLE #tmp
	DROP TABLE #tmpHdr
	DROP TABLE #tmpHikiate
	DROP TABLE #tmpShukkaYotei
    RETURN

	--END_PROC���x���̏���
	END_PROC:
		SELECT @RetCd
END